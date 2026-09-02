<?php

namespace App\Http\Resources\Api\V1;

use App\Enums\PermissionName;
use App\Enums\RoleName;
use App\Models\MonthlyFeedback;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin MonthlyFeedback
 */
class MonthlyFeedbackResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'year' => $this->year,
            'month' => $this->month,
            'session_date' => $this->session_date?->toDateString(),
            'submitted_at' => $this->submitted_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
            'editable' => $this->resolveEditable($request),
            'deletable' => $this->resolveDeletable($request),
            'master_teacher' => $this->whenLoaded('masterTeacher', fn () => [
                'id' => $this->masterTeacher->id,
                'full_name' => $this->masterTeacher->full_name,
            ]),
            'student' => $this->whenLoaded('student', fn () => [
                'id' => $this->student->id,
                'full_name' => $this->student->full_name,
                'student_code' => $this->student->student_code,
            ]),
            'items' => $this->whenLoaded('items', fn () => $this->items->map(function ($item) {
                $type = $item->target_type?->value ?? $item->target_type;

                return [
                    'id' => $item->id,
                    'target_type' => $type,
                    'target_id' => $item->target_id,
                    'target_name' => $item->resolveTargetName(),
                    'rating' => $item->rating,
                    'positive_points' => $item->positive_points,
                    'areas_for_improvement' => $item->areas_for_improvement,
                    'recommended_next_action' => $item->recommended_next_action,
                ];
            })->values()->all()),
        ];
    }

    private function resolveEditable(Request $request): bool
    {
        $user = $request->user();
        if ($user === null) {
            return false;
        }

        if ($user->isAdmin() && $user->can(PermissionName::FeedbackManage->value)) {
            return true;
        }

        if (! $user->hasRole(RoleName::MasterTeacher)) {
            return false;
        }

        $teacher = $user->teacherProfile;
        if ($teacher === null || $this->master_teacher_id !== $teacher->id) {
            return false;
        }

        if (! $teacher->activeMasterTeacherAssignments()->where('student_id', $this->student_id)->exists()) {
            return false;
        }

        return $this->isEditable();
    }

    private function resolveDeletable(Request $request): bool
    {
        $user = $request->user();
        if ($user === null) {
            return false;
        }

        if ($user->isAdmin() && $user->can(PermissionName::FeedbackManage->value)) {
            return true;
        }

        if (! $user->hasRole(RoleName::MasterTeacher)) {
            return false;
        }

        $teacher = $user->teacherProfile;
        if ($teacher === null || $this->master_teacher_id !== $teacher->id) {
            return false;
        }

        if (! $teacher->activeMasterTeacherAssignments()->where('student_id', $this->student_id)->exists()) {
            return false;
        }

        return $this->isDeletable();
    }
}
