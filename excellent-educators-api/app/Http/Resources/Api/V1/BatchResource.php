<?php

namespace App\Http\Resources\Api\V1;

use App\Models\Batch;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Batch
 */
class BatchResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'level_id' => $this->level_id,
            'name' => $this->name,
            'academic_year' => $this->academic_year,
            'year' => $this->year ?? $this->academic_year,
            'month' => $this->month,
            'enrolled_watermark' => $this->enrolled_watermark ?? 0,
            'status' => $this->status?->value ?? $this->status,
            'starts_on' => $this->starts_on?->toDateString(),
            'ends_on' => $this->ends_on?->toDateString(),
            'active_student_count' => $this->active_enrollments_count ?? $this->activeEnrollments()->count(),
            'max_active_students' => app(\App\Support\AppSettings::class)->maxActiveStudents(),
        ];
    }
}
