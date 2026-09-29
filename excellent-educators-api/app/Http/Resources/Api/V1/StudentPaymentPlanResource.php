<?php

namespace App\Http\Resources\Api\V1;

use App\Models\StudentPaymentPlan;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin StudentPaymentPlan
 */
class StudentPaymentPlanResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $student = $this->relationLoaded('student') ? $this->student : null;
        $batch = $student?->activeEnrollment?->batch;
        $level = $student?->academicLevel ?? $batch?->level;

        return [
            'id' => $this->id,
            'student_id' => $this->student_id,
            'payment_type' => $this->payment_type?->value ?? $this->payment_type,
            'payment_type_label' => $this->payment_type?->label(),
            'preferred_mode' => $this->preferred_mode?->value ?? $this->preferred_mode,
            'total_amount' => (float) $this->total_amount,
            'paid_amount' => (float) $this->paid_amount,
            'pending_amount' => (float) $this->pending_amount,
            'advance_amount' => (float) $this->advance_amount,
            'due_day' => $this->due_day,
            'start_date' => $this->start_date?->toDateString(),
            'next_due_date' => $this->next_due_date?->toDateString(),
            'next_due_amount' => $this->next_due_amount !== null ? (float) $this->next_due_amount : null,
            'overdue_amount' => (float) $this->overdue_amount,
            'last_payment_date' => $this->relationLoaded('payments') && $this->payments->isNotEmpty()
                ? ($this->payments->sortByDesc('created_at')->first()?->created_at?->toIso8601String()
                    ?? $this->last_payment_date?->toDateString())
                : ($this->last_payment_date?->toDateString()),
            'status' => $this->status?->value ?? $this->status,
            'status_label' => $this->status?->label(),
            'is_active' => (bool) $this->is_active,
            'student' => $student === null ? null : [
                'id' => $student->id,
                'full_name' => $student->full_name,
                'student_code' => $student->student_code,
                'email' => $student->user?->email,
                'phone' => $student->phone,
                'whatsapp_number' => $student->whatsapp_number,
                'level' => $level === null ? null : [
                    'id' => $level->id,
                    'name' => $level->name,
                ],
                'batch' => $batch === null ? null : [
                    'id' => $batch->id,
                    'name' => $batch->name,
                ],
            ],
            'payments' => $this->when(
                $this->relationLoaded('payments'),
                fn () => StudentPaymentResource::collection($this->payments),
            ),
        ];
    }
}
