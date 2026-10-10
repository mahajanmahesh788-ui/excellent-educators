<?php

namespace App\Http\Resources\Api\V1;

use App\Models\AcademicLevel;
use App\Models\StudentLevelJourney;
use App\Models\StudentProfile;
use App\Scheduling\MasterClassBalance;
use App\Support\StaticAcademicLevels;
use App\Support\StudentOnboardingSummary;
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
            'photo_url' => $this->photo_url,
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
            'has_learning_history' => $this->relationLoaded('levelJourneys')
                ? $this->levelJourneys->isNotEmpty()
                : $this->levelJourneys()->exists(),
            'level_path' => $this->when(
                $this->relationLoaded('levelJourneys'),
                fn () => $this->levelPath(),
            ),
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
            'payment' => $this->paymentSummary(),
            ...($this->onboardingSummary($request)),
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function onboardingSummary(Request $request): array
    {
        if (! StudentOnboardingSummary::shouldInclude($request)) {
            return [];
        }

        return StudentOnboardingSummary::forStudent($this->resource);
    }

    /**
     * @return array<string, mixed>|null
     */
    private function paymentSummary(): ?array
    {
        $plan = $this->relationLoaded('activePaymentPlan')
            ? $this->activePaymentPlan
            : $this->activePaymentPlan()->first();

        if ($plan === null) {
            return null;
        }

        return [
            'plan_id' => $plan->id,
            'payment_type' => $plan->payment_type?->value ?? $plan->payment_type,
            'status' => $plan->status?->value ?? $plan->status,
            'total_amount' => (float) $plan->total_amount,
            'paid_amount' => (float) $plan->paid_amount,
            'pending_amount' => (float) $plan->pending_amount,
            'advance_amount' => (float) $plan->advance_amount,
            'next_due_date' => $plan->next_due_date?->toDateString(),
            'next_due_amount' => $plan->next_due_amount !== null ? (float) $plan->next_due_amount : null,
            'overdue_amount' => (float) $plan->overdue_amount,
            'last_payment_date' => $plan->relationLoaded('payments') && $plan->payments->isNotEmpty()
                ? ($plan->payments->sortByDesc('created_at')->first()?->created_at?->toIso8601String()
                    ?? $plan->last_payment_date?->toDateString())
                : ($plan->last_payment_date?->toDateString()),
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
        if (isset($this->master_class_balance) && is_array($this->master_class_balance)) {
            $balance = $this->master_class_balance;
        } else {
            $balance = app(MasterClassBalance::class)->snapshot($this->resource);
        }

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

    /**
     * Single-line level progress for admin/teacher student profiles.
     *
     * @return list<array{level_id: ?string, number: int, name: string, status: string, date: ?string}>
     */
    private function levelPath(): array
    {
        $journeys = $this->levelJourneys
            ->loadMissing('level')
            ->sortBy(fn (StudentLevelJourney $journey) => $journey->started_at?->timestamp ?? 0)
            ->values();

        /** @var array<int, array{level_id: ?string, number: int, name: string, status: string, date: ?string}> $byNumber */
        $byNumber = [];

        foreach ($journeys as $journey) {
            $level = $journey->level;
            $number = $level?->number
                ?? StaticAcademicLevels::parseNumberFromName($level?->name);
            if ($number === null) {
                continue;
            }

            $completed = $journey->ended_at !== null;
            $byNumber[(int) $number] = [
                'level_id' => $level?->id,
                'number' => (int) $number,
                'name' => $level?->name ?? StaticAcademicLevels::label((int) $number),
                'status' => $completed ? 'completed' : 'current',
                // Completion date for finished levels; current/upcoming omit a date.
                'date' => $completed ? $journey->ended_at?->toDateString() : null,
            ];
        }

        $level = $this->academicLevel ?? $this->activeEnrollment?->batch?->level;
        $currentNumber = $level?->number
            ?? StaticAcademicLevels::parseNumberFromName($level?->name);

        if ($byNumber === [] && $currentNumber !== null) {
            $byNumber[(int) $currentNumber] = [
                'level_id' => $level?->id,
                'number' => (int) $currentNumber,
                'name' => $level?->name ?? StaticAcademicLevels::label((int) $currentNumber),
                'status' => 'current',
                'date' => null,
            ];
        } elseif ($currentNumber !== null && ! isset($byNumber[(int) $currentNumber])) {
            $byNumber[(int) $currentNumber] = [
                'level_id' => $level?->id,
                'number' => (int) $currentNumber,
                'name' => $level?->name ?? StaticAcademicLevels::label((int) $currentNumber),
                'status' => 'current',
                'date' => null,
            ];
        }

        $maxReached = $byNumber === [] ? 0 : (int) max(array_keys($byNumber));
        $maxShow = min(StaticAcademicLevels::MAX, max($maxReached + 1, 1));

        $existing = AcademicLevel::query()
            ->whereNotNull('number')
            ->whereBetween('number', [1, $maxShow])
            ->get()
            ->keyBy('number');

        $nodes = [];
        for ($number = 1; $number <= $maxShow; $number++) {
            if (isset($byNumber[$number])) {
                $nodes[] = $byNumber[$number];
                continue;
            }

            $existingLevel = $existing->get($number);
            $nodes[] = [
                'level_id' => $existingLevel?->id,
                'number' => $number,
                'name' => $existingLevel?->name ?? StaticAcademicLevels::label($number),
                'status' => 'upcoming',
                'date' => null,
            ];
        }

        return $nodes;
    }
}
