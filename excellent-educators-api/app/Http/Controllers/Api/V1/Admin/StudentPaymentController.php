<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Api\V1\Concerns\EnsuresAgentOwnsStudent;
use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\StudentPaymentPlanResource;
use App\Http\Resources\Api\V1\StudentPaymentResource;
use App\Models\StudentPayment;
use App\Models\StudentProfile;
use App\Payments\PaymentOverviewService;
use App\Payments\PaymentPlanService;
use App\Support\ApiResponse;
use App\Support\ErrorCode;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;

class StudentPaymentController extends Controller
{
    use EnsuresAgentOwnsStudent;

    public function __construct(
        private readonly PaymentPlanService $plans,
        private readonly PaymentOverviewService $overview,
    ) {}

    public function overview(Request $request): JsonResponse
    {
        $actorId = $request->user()?->isAgent() ? $request->user()->id : null;

        return ApiResponse::success('Payment overview fetched.', $this->overview->summaryCards($actorId));
    }

    public function index(Request $request): JsonResponse
    {
        $filters = $request->validate([
            'status' => ['nullable', 'string'],
            'period' => ['nullable', 'string', Rule::in(['this_month', 'last_month'])],
            'from' => ['nullable', 'date'],
            'to' => ['nullable', 'date'],
            'payment_type' => ['nullable', Rule::in(['full', 'partial'])],
            'preferred_mode' => ['nullable', Rule::in(['online', 'offline'])],
            'level_id' => ['nullable', 'ulid'],
            'batch_id' => ['nullable', 'ulid'],
            'search' => ['nullable', 'string', 'max:120'],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:100'],
        ]);

        if ($request->user()?->isAgent()) {
            $filters['created_by_user_id'] = $request->user()->id;
        }

        $page = $this->overview->listPlans($filters, (int) ($filters['per_page'] ?? 20));
        $actorId = $request->user()?->isAgent() ? $request->user()->id : null;

        return ApiResponse::success(
            'Payment plans fetched.',
            [
                'items' => StudentPaymentPlanResource::collection($page->items())->resolve(),
                'summary' => $this->overview->summaryCards($actorId),
            ],
            [
                'current_page' => $page->currentPage(),
                'last_page' => $page->lastPage(),
                'per_page' => $page->perPage(),
                'total' => $page->total(),
            ],
        );
    }

    public function show(Request $request, StudentProfile $student): JsonResponse
    {
        $this->ensureAgentOwnsStudent($request, $student);
        $plan = $this->plans->activePlanFor($student);
        if ($plan === null) {
            return ApiResponse::success('No payment plan.', ['plan' => null]);
        }

        return ApiResponse::success(
            'Payment plan fetched.',
            ['plan' => (new StudentPaymentPlanResource($plan))->resolve()],
        );
    }

    public function storePlan(Request $request, StudentProfile $student): JsonResponse
    {
        $this->ensureAgentOwnsStudent($request, $student);
        $data = $request->validate([
            'payment_type' => ['required', Rule::in(['full', 'partial'])],
            'preferred_mode' => ['nullable', Rule::in(['online', 'offline'])],
            'total_amount' => ['nullable', 'numeric', 'min:0'],
            'initial_amount' => ['nullable', 'numeric', 'min:0'],
            'payment_amount' => ['nullable', 'numeric', 'min:0'],
            'notes' => ['nullable', 'string', 'max:2000'],
            'due_day' => ['nullable', 'integer', 'min:1', 'max:28'],
            'start_date' => ['nullable', 'date'],
            'reason' => ['nullable', 'string', 'max:500'],
        ]);

        $existing = $this->plans->activePlanFor($student);
        if ($existing !== null) {
            $plan = $this->plans->changePlan($existing, $data, $request->user()?->id);
        } else {
            $plan = $this->plans->createForStudent($student, $data, $request->user()?->id);
        }

        return ApiResponse::success(
            'Payment plan saved.',
            ['plan' => (new StudentPaymentPlanResource($plan->load('payments')))->resolve()],
            status: 201,
        );
    }

    public function storePayment(Request $request, StudentProfile $student): JsonResponse
    {
        $this->ensureAgentOwnsStudent($request, $student);
        $plan = $this->plans->activePlanFor($student);
        if ($plan === null) {
            return ApiResponse::error(
                'Create a payment plan before recording payments.',
                ErrorCode::VALIDATION_ERROR,
                null,
                422,
            );
        }

        $data = $request->validate([
            'amount' => ['required', 'numeric', 'min:0.01'],
            'payment_mode' => ['required', Rule::in(['online', 'offline'])],
            'notes' => ['nullable', 'string', 'max:2000'],
            'receipt' => ['nullable', 'file', 'max:5120', 'mimes:jpg,jpeg,png,pdf,webp'],
        ]);

        $receiptPath = null;
        if ($request->hasFile('receipt')) {
            $receiptPath = $request->file('receipt')->store(
                'payment-receipts/'.$student->id,
                'public',
            );
        }

        $beforePending = (float) $plan->pending_amount;
        $payment = $this->plans->recordSuccessfulPayment($plan, [
            'amount' => $data['amount'],
            'payment_mode' => $data['payment_mode'],
            'notes' => $data['notes'] ?? null,
            'receipt_path' => $receiptPath,
        ], $request->user()?->id);

        $fresh = $this->plans->activePlanFor($student);

        return ApiResponse::success(
            'Payment recorded.',
            [
                'payment' => (new StudentPaymentResource($payment))->resolve(),
                'plan' => (new StudentPaymentPlanResource($fresh))->resolve(),
                'delta' => [
                    'previous_pending' => $beforePending,
                    'payment_received' => (float) $payment->amount,
                    'new_pending' => (float) ($fresh?->pending_amount ?? 0),
                ],
            ],
            status: 201,
        );
    }

    public function reminderMessage(Request $request, StudentProfile $student): JsonResponse
    {
        $this->ensureAgentOwnsStudent($request, $student);
        $plan = $this->plans->activePlanFor($student);
        if ($plan === null || (float) $plan->pending_amount <= 0) {
            return ApiResponse::error(
                'Student has no pending payment.',
                ErrorCode::VALIDATION_ERROR,
                null,
                422,
            );
        }

        $phone = $student->whatsapp_number ?: $student->phone;
        $digits = preg_replace('/\D+/', '', (string) $phone) ?? '';
        if (strlen($digits) === 10) {
            $digits = '91'.$digits;
        }

        $due = $plan->next_due_date?->format('d-M-Y') ?? 'soon';
        $amount = number_format((float) ($plan->next_due_amount ?: $plan->pending_amount), 0);
        $pending = number_format((float) $plan->pending_amount, 0);
        $batch = $student->activeEnrollment?->batch?->name;
        $level = $student->academicLevel?->name;
        $course = trim(($level ?? '').($batch ? ' · '.$batch : '')) ?: 'your course';

        $message = "Hello {$student->full_name},\n\n"
            ."This is a friendly payment reminder from Excellent Educators regarding your pending payment.\n\n"
            ."Course: {$course}\n"
            ."Pending Amount: ₹{$pending}\n"
            ."Next Due Amount: ₹{$amount}\n"
            ."Due Date: {$due}\n\n"
            ."Please complete the payment at your convenience.\n"
            ."If you have already made the payment, please share the payment details with us.\n\n"
            ."Thank you,\nExcellent Educators";

        $waUrl = $digits !== ''
            ? 'https://wa.me/'.$digits.'?text='.rawurlencode($message)
            : null;

        return ApiResponse::success('Reminder prepared.', [
            'message' => $message,
            'whatsapp_url' => $waUrl,
            'phone' => $student->phone,
            'tel_url' => $student->phone ? 'tel:'.$student->phone : null,
        ]);
    }

    public function storeReceipt(
        Request $request,
        StudentProfile $student,
        StudentPayment $payment,
    ): JsonResponse {
        $this->ensureAgentOwnsStudent($request, $student);
        if ($payment->student_id !== $student->id) {
            return ApiResponse::error('Payment not found.', ErrorCode::NOT_FOUND, null, 404);
        }

        $data = $request->validate([
            'receipt' => ['required', 'file', 'max:5120', 'mimes:pdf'],
        ]);

        if ($payment->receipt_path) {
            Storage::disk('public')->delete($payment->receipt_path);
        }

        $path = $data['receipt']->store(
            'payment-receipts/'.$student->id,
            'public',
        );
        $payment->update(['receipt_path' => $path]);

        return ApiResponse::success(
            'Receipt saved.',
            ['payment' => (new StudentPaymentResource($payment->fresh()))->resolve()],
        );
    }

    public function updatePayment(
        Request $request,
        StudentProfile $student,
        StudentPayment $payment,
    ): JsonResponse {
        $this->ensureAgentOwnsStudent($request, $student);
        if ($payment->student_id !== $student->id) {
            return ApiResponse::error('Payment not found.', ErrorCode::NOT_FOUND, null, 404);
        }

        $data = $request->validate([
            'amount' => ['sometimes', 'numeric', 'min:0.01'],
            'payment_mode' => ['sometimes', Rule::in(['online', 'offline'])],
            'payment_date' => ['sometimes', 'nullable', 'date'],
            'notes' => ['sometimes', 'nullable', 'string', 'max:2000'],
        ]);

        $updated = $this->plans->updatePayment($payment, $data, $request->user()?->id);
        $fresh = $this->plans->activePlanFor($student);

        return ApiResponse::success('Payment updated.', [
            'payment' => (new StudentPaymentResource($updated))->resolve(),
            'plan' => $fresh === null ? null : (new StudentPaymentPlanResource($fresh))->resolve(),
        ]);
    }

    public function voidPayment(
        Request $request,
        StudentProfile $student,
        StudentPayment $payment,
    ): JsonResponse {
        $this->ensureAgentOwnsStudent($request, $student);
        if ($payment->student_id !== $student->id) {
            return ApiResponse::error('Payment not found.', ErrorCode::NOT_FOUND, null, 404);
        }

        $data = $request->validate([
            'reason' => ['nullable', 'string', 'max:500'],
        ]);

        $voided = $this->plans->voidPayment($payment, $request->user()?->id, $data['reason'] ?? null);
        $fresh = $this->plans->activePlanFor($student);

        return ApiResponse::success('Payment voided.', [
            'payment' => (new StudentPaymentResource($voided))->resolve(),
            'plan' => $fresh === null ? null : (new StudentPaymentPlanResource($fresh))->resolve(),
        ]);
    }
}
