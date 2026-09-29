<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\StudentPaymentPlanResource;
use App\Http\Resources\Api\V1\StudentPaymentResource;
use App\Models\StudentProfile;
use App\Payments\PaymentOverviewService;
use App\Payments\PaymentPlanService;
use App\Support\ApiResponse;
use App\Support\ErrorCode;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class StudentPaymentController extends Controller
{
    public function __construct(
        private readonly PaymentPlanService $plans,
        private readonly PaymentOverviewService $overview,
    ) {}

    public function overview(): JsonResponse
    {
        return ApiResponse::success('Payment overview fetched.', $this->overview->summaryCards());
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

        $page = $this->overview->listPlans($filters, (int) ($filters['per_page'] ?? 20));

        return ApiResponse::success(
            'Payment plans fetched.',
            [
                'items' => StudentPaymentPlanResource::collection($page->items())->resolve(),
                'summary' => $this->overview->summaryCards(),
            ],
            [
                'current_page' => $page->currentPage(),
                'last_page' => $page->lastPage(),
                'per_page' => $page->perPage(),
                'total' => $page->total(),
            ],
        );
    }

    public function show(StudentProfile $student): JsonResponse
    {
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

    public function reminderMessage(StudentProfile $student): JsonResponse
    {
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
}
