<?php

namespace App\Http\Resources\Api\V1;

use App\Models\AcademicLevel;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin AcademicLevel
 */
class AcademicLevelResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $batches = $this->relationLoaded('batches')
            ? $this->batches
            : $this->batches()->withCount('activeEnrollments')->get();

        $batchesCount = (int) ($this->batches_count ?? $batches->count());
        $studentCount = (int) $batches->sum(fn ($b) => $b->active_enrollments_count ?? $b->activeStudentCount());

        $masterTeachers = $this->relationLoaded('masterTeachers')
            ? $this->masterTeachers
            : $this->masterTeachers()->with('user')->get();

        return [
            'id' => $this->id,
            'name' => $this->name,
            'academic_year' => $this->academic_year,
            'master_classes_per_month' => (int) ($this->master_classes_per_month ?? 1),
            'status' => $this->status,
            'batch_count' => $batchesCount,
            'batches_count' => $batchesCount,
            'student_count' => $studentCount,
            'students_count' => $studentCount,
            'batches' => BatchResource::collection($batches)->resolve(),
            'master_teachers' => TeacherResource::collection($masterTeachers)->resolve(),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
