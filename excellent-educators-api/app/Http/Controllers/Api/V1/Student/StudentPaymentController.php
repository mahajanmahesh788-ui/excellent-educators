<?php

namespace App\Http\Controllers\Api\V1\Student;

use App\Enums\PaymentMode;
use App\Enums\PaymentTransactionStatus;
use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\StudentPaymentPlanResource;
use App\Http\Resources\Api\V1\StudentPaymentResource;
use App\Models\StudentPayment;
use App\Payments\PaymentPlanService;
use App\Payments\PaymentSettings;
use App\Support\ApiResponse;
use App\Support\AppClock;
use App\Support\ErrorCode;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class StudentPaymentController extends Controller
{
    public function __construct(
        private readonly PaymentPlanService $plans,
        private readonly PaymentSettings $settings,
    ) {}

    public function show(Request $request): JsonResponse
    {
        $student = $request->user()?->studentProfile;
        if ($student === null) {
            return ApiResponse::error('Student profile not found.', ErrorCode::NOT_FOUND, null, 404);
        }

        $plan = $this->plans->activePlanFor($student);

        return ApiResponse::success('Payment status fetched.', [
            'plan' => $plan === null ? null : (new StudentPaymentPlanResource($plan))->resolve(),
            'online_enabled' => $this->settings->onlineEnabled(),
        ]);
    }

    public function initiateOnline(Request $request): JsonResponse
    {
        if (! $this->settings->onlineEnabled()) {
            return ApiResponse::error('Online payment is disabled.', ErrorCode::VALIDATION_ERROR, null, 422);
        }

        $student = $request->user()?->studentProfile;
        if ($student === null) {
            return ApiResponse::error('Student profile not found.', ErrorCode::NOT_FOUND, null, 404);
        }

        $plan = $this->plans->activePlanFor($student);
        if ($plan === null || (float) $plan->pending_amount <= 0) {
            return ApiResponse::error('No pending payment.', ErrorCode::VALIDATION_ERROR, null, 422);
        }

        $data = $request->validate([
            'amount' => ['nullable', 'numeric', 'min:0.01'],
        ]);

        $pending = round((float) $plan->pending_amount, 2);
        $amount = round((float) ($data['amount'] ?? ($plan->next_due_amount ?: $pending)), 2);
        if ($amount > $pending + 0.001) {
            $left = rtrim(rtrim(number_format($pending, 2, '.', ''), '0'), '.');

            return ApiResponse::error(
                "Only ₹{$left} left. Amount cannot exceed the pending amount.",
                ErrorCode::VALIDATION_ERROR,
                null,
                422,
            );
        }
        if ($amount <= 0) {
            return ApiResponse::error('Nothing to pay.', ErrorCode::VALIDATION_ERROR, null, 422);
        }

        $orderId = 'ee_'.Str::lower((string) Str::ulid());

        $payment = StudentPayment::query()->create([
            'student_id' => $student->id,
            'payment_plan_id' => $plan->id,
            'amount' => $amount,
            'payment_mode' => PaymentMode::Online,
            'payment_date' => AppClock::now()->toDateString(),
            'status' => PaymentTransactionStatus::Pending,
            'gateway' => 'manual',
            'gateway_order_id' => $orderId,
            'notes' => 'Online payment initiated',
            'created_by' => $request->user()?->id,
        ]);

        // No third-party gateway is configured yet. Return a server-verified
        // pending order the client can complete via confirm (or future gateway callback).
        return ApiResponse::success('Online payment initiated.', [
            'payment' => (new StudentPaymentResource($payment))->resolve(),
            'order_id' => $orderId,
            'amount' => $amount,
            'checkout' => [
                'provider' => 'manual',
                'message' => 'Complete payment with your admin or wire a gateway to this order_id.',
            ],
        ], status: 201);
    }

    public function confirmOnline(Request $request): JsonResponse
    {
        $data = $request->validate([
            'order_id' => ['required', 'string'],
            'transaction_id' => ['nullable', 'string', 'max:120'],
        ]);

        $student = $request->user()?->studentProfile;
        $payment = StudentPayment::query()
            ->where('gateway_order_id', $data['order_id'])
            ->where('student_id', $student?->id)
            ->first();

        if ($payment === null) {
            return ApiResponse::error('Payment order not found.', ErrorCode::NOT_FOUND, null, 404);
        }

        if ($payment->status === PaymentTransactionStatus::Successful) {
            $plan = $this->plans->activePlanFor($student);

            return ApiResponse::success('Payment already confirmed.', [
                'payment' => (new StudentPaymentResource($payment))->resolve(),
                'plan' => $plan === null ? null : (new StudentPaymentPlanResource($plan))->resolve(),
            ]);
        }

        $payment->fill([
            'status' => PaymentTransactionStatus::Successful,
            'transaction_id' => $data['transaction_id'] ?? $payment->gateway_order_id,
            'gateway_payment_id' => $data['transaction_id'] ?? $payment->gateway_payment_id,
            'payment_date' => AppClock::now()->toDateString(),
        ]);
        $payment->save();

        $fresh = $this->plans->recalculate($payment->plan, $request->user()?->id);

        return ApiResponse::success('Payment confirmed.', [
            'payment' => (new StudentPaymentResource($payment->fresh()))->resolve(),
            'plan' => (new StudentPaymentPlanResource($fresh))->resolve(),
        ]);
    }
}
