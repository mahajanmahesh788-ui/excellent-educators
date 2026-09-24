<?php

namespace App\Http\Resources\Api\V1;

use App\Models\StudentProfile;
use App\Scheduling\MasterClassBalance;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin StudentProfile
 */
class StudentResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $batch = $this->activeEnrollment?->batch;
        $master = $this->activeMasterTeacherAssignment?->teacher;

        $level = $this->academicLevel ?? $batch?->level;
        $masterTeachers = $level !== null
            ? ($level->relationLoaded('masterTeachers')
                ? $level->masterTeachers
                : $level->masterTeachers()->with('user')->get())
            : collect();

        return [
            'id' => $this->id,
            'student_code' => $this->student_code,
            'full_name' => $this->full_name,
            'gender' => $this->gender?->value ?? $this->gender,
            'email' => $this->user?->email,
            'phone' => $this->phone,
            'whatsapp_number' => $this->whatsapp_number,
            'address' => $this->address,
            'class_grade' => $this->class_grade,
            'status' => $this->status?->value ?? $this->status,
            'guardian_name' => $this->guardian_name,
            'guardian_phone' => $this->guardian_phone,
            'created_at' => $this->created_at?->toIso8601String(),
            'level' => $level === null ? null : [
                'id' => $level->id,
                'name' => $level->name,
            ],
            'batch' => $batch === null ? null : [
                'id' => $batch->id,
                'name' => $batch->name,
                'status' => $batch->status?->value ?? $batch->status,
                'starts_on' => $batch->starts_on?->toDateString(),
            ],
            'journey_started' => $this->relationLoaded('currentLevelJourney')
                ? $this->currentLevelJourney !== null
                : $this->currentLevelJourney()->exists(),
            'master_teacher' => $master === null ? null : [
                'id' => $master->id,
                'full_name' => $master->full_name,
            ],
            'master_teachers' => TeacherResource::collection($masterTeachers)->resolve(),
            'aptitude_assessment' => $this->when(
                $this->relationLoaded('latestAptitudeAssessmentResult'),
                fn () => $this->aptitudeAssessmentSummary(),
            ),
            'feedback' => $this->feedbackSummary(),
            'master_class' => $this->masterClassSummary(),
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function feedbackSummary(): array
    {
        $currentMonthSessions = (int) ($this->feedback_current_month_sessions ?? 0);
        $totalSessions = (int) ($this->feedback_total_sessions ?? 0);

        return [
            'total_sessions' => $totalSessions,
            'current_month_sessions' => $currentMonthSessions,
            'current_month_completed' => $currentMonthSessions > 0,
            'filter_year' => $this->feedback_filter_year ?? null,
            'filter_month' => $this->feedback_filter_month ?? null,
            'filter_month_sessions' => (int) ($this->feedback_filter_sessions ?? 0),
            'filter_month_completed' => (int) ($this->feedback_filter_sessions ?? 0) > 0,
            'overall_average' => $this->feedbackOverallAverage(),
            'can_rate' => (bool) ($this->can_rate_this_month ?? false),
            'can_edit_rating' => (bool) ($this->can_edit_rating_this_month ?? false),
            'monthly_feedback_id' => $this->monthly_feedback_id ?? null,
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function masterClassSummary(): array
    {
        $balance = app(MasterClassBalance::class)->snapshot($this->resource);

        return [
            'allotment' => $balance['allotment'],
            'remaining' => $balance['remaining'],
            'used' => $balance['used'],
            'override' => $this->master_classes_per_month,
        ];
    }

    private function feedbackOverallAverage(): ?float
    {
        if (! isset($this->feedback_overall_average)) {
            return null;
        }

        if ($this->feedback_overall_average === null) {
            return null;
        }

        return round((float) $this->feedback_overall_average, 1);
    }

    /**
     * @return array<string, mixed>
     */
    private function aptitudeAssessmentSummary(): array
    {
        $result = $this->latestAptitudeAssessmentResult;
        if ($result === null) {
            return [
                'status' => 'pending',
                'submitted_at' => null,
                'assessment_title' => null,
            ];
        }

        $attempt = $result->attempt;
        $assessment = $attempt?->assessment;

        return [
            'status' => 'submitted',
            'submitted_at' => $attempt?->submitted_at?->toIso8601String(),
            'assessment_title' => $assessment?->title,
        ];
    }
}
