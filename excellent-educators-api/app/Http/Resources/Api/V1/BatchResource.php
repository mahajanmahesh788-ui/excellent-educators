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
        $teacher = $this->activeTeacherAssignment?->teacher;

        return [
            'id' => $this->id,
            'name' => $this->name,
            'academic_year' => $this->academic_year,
            'status' => $this->status?->value ?? $this->status,
            'starts_on' => $this->starts_on?->toDateString(),
            'ends_on' => $this->ends_on?->toDateString(),
            'active_student_count' => $this->active_enrollments_count ?? $this->activeEnrollments()->count(),
            'max_active_students' => (int) config('excellent_educators.batch.max_active_students', 40),
            'career_compass_level' => $this->whenLoaded(
                'careerCompassLevel',
                fn () => CareerCompassLevelResource::make($this->careerCompassLevel)->resolve(),
            ),
            'common_teacher' => $teacher === null ? null : [
                'id' => $teacher->id,
                'full_name' => $teacher->full_name,
            ],
        ];
    }
}
