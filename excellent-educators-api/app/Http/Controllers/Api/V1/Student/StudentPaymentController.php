<?php

namespace App\Http\Controllers\Api\V1\Student;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\StudentPaymentPlanResource;
use App\Http\Resources\Api\V1\StudentPaymentResource;
use App\Models\StudentPayment;
use App\Payments\PaymentPlanService;
use App\Support\ApiResponse;
use App\Support\ErrorCode;
use App\Support\PaymentReceiptStorage;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\StreamedResponse;

class StudentPaymentController extends Controller
{
    public function __construct(
        private readonly PaymentPlanService $plans,
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
            // Students never self-pay; staff records payments. Keep flag false so
            // older clients hide Pay Now even if a gateway is added later.
            'online_enabled' => false,
        ]);
    }

    public function initiateOnline(Request $request): JsonResponse
    {
        return ApiResponse::error(
            'Student online payment is disabled. Please pay through the institute; staff will record it.',
            ErrorCode::VALIDATION_ERROR,
            null,
            422,
        );
    }

    public function confirmOnline(Request $request): JsonResponse
    {
        return ApiResponse::error(
            'Student online payment is disabled. Please pay through the institute; staff will record it.',
            ErrorCode::VALIDATION_ERROR,
            null,
            422,
        );
    }

    public function storeReceipt(Request $request, StudentPayment $payment): JsonResponse
    {
        $student = $request->user()?->studentProfile;
        if ($student === null) {
            return ApiResponse::error('Student profile not found.', ErrorCode::NOT_FOUND, null, 404);
        }

        if ($payment->student_id !== $student->id) {
            return ApiResponse::error('Payment not found.', ErrorCode::NOT_FOUND, null, 404);
        }

        $data = $request->validate([
            'receipt' => ['required', 'file', 'max:5120', 'mimes:pdf'],
        ]);

        PaymentReceiptStorage::delete($payment->receipt_path);

        $path = PaymentReceiptStorage::store($data['receipt'], $student->id);
        $payment->update(['receipt_path' => $path]);

        return ApiResponse::success(
            'Receipt saved.',
            ['payment' => (new StudentPaymentResource($payment->fresh()))->resolve()],
        );
    }

    public function showReceipt(Request $request, StudentPayment $payment): StreamedResponse|JsonResponse
    {
        $student = $request->user()?->studentProfile;
        if ($student === null) {
            return ApiResponse::error('Student profile not found.', ErrorCode::NOT_FOUND, null, 404);
        }

        if ($payment->student_id !== $student->id) {
            return ApiResponse::error('Payment not found.', ErrorCode::NOT_FOUND, null, 404);
        }

        return PaymentReceiptStorage::response(
            $payment->receipt_path,
            'EE-Receipt-'.$payment->id.'.pdf',
        );
    }
}
