<?php

namespace App\Http\Resources\Api\V1;

use App\Models\GeneratedBill;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin GeneratedBill
 */
class GeneratedBillResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'bill_number' => $this->bill_number,
            'full_name' => $this->full_name,
            'email' => $this->email,
            'phone' => $this->phone,
            'whatsapp_number' => $this->whatsapp_number,
            'address' => $this->address,
            'class_grade' => $this->class_grade,
            'gender' => $this->gender?->value ?? $this->gender,
            'guardian_name' => $this->guardian_name,
            'guardian_phone' => $this->guardian_phone,
            'payment_type' => $this->payment_type?->value ?? $this->payment_type,
            'payment_type_label' => $this->payment_type?->label()
                ?? ($this->payment_type === 'partial' ? 'Partial' : 'Full'),
            'payment_mode' => $this->payment_mode?->value ?? $this->payment_mode,
            'total_amount' => (float) $this->total_amount,
            'paid_amount' => (float) $this->paid_amount,
            'pending_amount' => $this->pendingAmount(),
            'notes' => $this->notes,
            'bill_date' => $this->bill_date?->toDateString(),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
