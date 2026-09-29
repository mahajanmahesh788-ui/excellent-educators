<?php

namespace App\Http\Resources\Api\V1;

use App\Models\StudentPayment;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Storage;

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
            'receipt_url' => $this->receipt_path
                ? Storage::disk('public')->url($this->receipt_path)
                : null,
            'gateway' => $this->gateway,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
