<?php

namespace App\Http\Resources\Api\V1;

use App\Models\StudentPayment;
use App\Support\PaymentReceiptStorage;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin StudentPayment
 */
class StudentPaymentResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'student_id' => $this->student_id,
            'payment_plan_id' => $this->payment_plan_id,
            'amount' => (float) $this->amount,
            'payment_mode' => $this->payment_mode?->value ?? $this->payment_mode,
            'payment_date' => $this->created_at?->toIso8601String()
                ?? ($this->payment_date ? $this->payment_date->toDateString() : null),
            'status' => $this->status?->value ?? $this->status,
            'status_label' => $this->status?->label(),
            'notes' => $this->notes,
            'receipt_url' => $this->authorizedReceiptUrl($request),
            'gateway' => $this->gateway,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }

    private function authorizedReceiptUrl(Request $request): ?string
    {
        if (! PaymentReceiptStorage::exists($this->receipt_path)) {
            return null;
        }

        $user = $request->user();
        $studentProfileId = $user?->studentProfile?->id;
        if ($studentProfileId !== null && $studentProfileId === $this->student_id) {
            return url('/api/v1/student/payments/'.$this->id.'/receipt');
        }

        return url('/api/v1/admin/payments/students/'.$this->student_id.'/payments/'.$this->id.'/receipt');
    }
}
