<?php

namespace App\Learning;

use App\Actions\Assessments\CalculateAssessmentResult;
use App\Actions\Learning\StartStudentLevelJourney;
use App\Exceptions\ApiException;
use App\Models\StudentLevelJourney;
use App\Models\StudentProfile;
use App\Models\WeeklyAssignmentAttempt;
use App\Models\WeeklyLearning;
use App\Support\AppClock;
use App\Support\ErrorCode;
use App\Support\StudentActivity;
use Illuminate\Support\Collection;

class LearningJournalService
{
    public function __construct(
        private readonly StartStudentLevelJourney $startStudentLevelJourney,
        private readonly CalculateAssessmentResult $calculateAssessmentResult,
    ) {}

    /**
     * @return array<string, mixed>
     */
    public function dashboard(StudentProfile $student, bool $staffView): array
    {
        $this->startStudentLevelJourney->ensure($student);
        $student->loadMissing('academicLevel');

        $journey = $this->currentJourney($student);
        if ($journey === null) {
            return [
                'current_level' => null,
                'current_week' => null,
                'next_action' => 'awaiting_level',
                'progress' => ['completed_weeks' => 0, 'total_weeks' => 0],
                'week' => null,
            ];
        }

        $currentWeek = $journey->weekNumberAt(AppClock::now());
        $unit = WeeklyLearning::query()
            ->with('questions.options.dimensionCodes')
            ->where('level_id', $journey->level_id)
            ->where('week_number', $currentWeek)
            ->first();

        $attempts = $unit === null
            ? collect()
            : WeeklyAssignmentAttempt::query()
                ->where('student_id', $student->id)
                ->where('weekly_learning_id', $unit->id)
                ->orderBy('attempt_number')
                ->get();

        $attemptCount = $attempts->count();
        $nextAction = match (true) {
            $unit === null => 'awaiting_content',
            $attemptCount === 0 => 'complete_assignment',
            default => 'assignment_complete',
        };

        $published = WeeklyLearning::query()->where('level_id', $journey->level_id)->count();
        $completedWeeks = WeeklyAssignmentAttempt::query()
            ->where('student_id', $student->id)
            ->where('student_level_journey_id', $journey->id)
            ->distinct()
            ->count('weekly_learning_id');

        return [
            'current_level' => [
                'id' => $journey->level_id,
                'name' => $journey->level?->name ?? $student->academicLevel?->name,
            ],
            'current_week' => $currentWeek,
            'next_action' => $nextAction,
            'cta_label' => $this->ctaLabel($nextAction, $currentWeek, $journey->level?->name),
            'progress' => [
                'completed_weeks' => $completedWeeks,
                'total_weeks' => max($published, 52),
            ],
            'week' => $this->weekPayload($student, $journey, $currentWeek, $unit, $attempts, $staffView, unlocked: true),
        ];
    }

    /**
     * @return array<string, mixed>
     */
    public function journal(StudentProfile $student, bool $staffView): array
    {
        $this->startStudentLevelJourney->ensure($student);
        $student->loadMissing('academicLevel');
        $journeys = StudentLevelJourney::query()
            ->with('level')
            ->where('student_id', $student->id)
            ->orderByRaw('ended_at is null')
            ->orderBy('started_at')
            ->orderBy('created_at')
            ->get();

        $levels = [];
        foreach ($journeys as $journey) {
            $maxWeek = $journey->weekNumberAt(AppClock::now());
            $units = WeeklyLearning::query()
                ->with('questions.options.dimensionCodes')
                ->where('level_id', $journey->level_id)
                ->where('week_number', '<=', $maxWeek)
                ->orderBy('week_number')
                ->get()
                ->keyBy('week_number');

            $attemptsByUnit = WeeklyAssignmentAttempt::query()
                ->where('student_id', $student->id)
                ->where('student_level_journey_id', $journey->id)
                ->orderBy('attempt_number')
                ->get()
                ->groupBy('weekly_learning_id');

            $weeks = [];
            for ($week = 1; $week <= $maxWeek; $week++) {
                $unit = $units->get($week);
                $attempts = $unit === null ? collect() : ($attemptsByUnit->get($unit->id) ?? collect());
                $weeks[] = $this->weekPayload($student, $journey, $week, $unit, $attempts, $staffView, unlocked: true, compact: true);
            }

            $levels[] = [
                'level' => [
                    'id' => $journey->level_id,
                    'name' => $journey->level?->name,
                ],
                'journey_id' => $journey->id,
                'is_current' => $journey->isCurrent(),
                'started_at' => $journey->started_at?->toIso8601String(),
                'ended_at' => $journey->ended_at?->toIso8601String(),
                'week_count' => $maxWeek,
                'weeks' => $weeks,
            ];
        }

        return [
            'student' => $staffView ? [
                'id' => $student->id,
                'full_name' => $student->full_name,
                'current_level' => $student->academicLevel?->name,
            ] : [
                'id' => $student->id,
            ],
            'levels' => $levels,
        ];
    }

    /**
     * @return array<string, mixed>
     */
    public function weekDetail(StudentProfile $student, string $journeyId, int $weekNumber, bool $staffView): array
    {
        $this->startStudentLevelJourney->ensure($student);
        $journey = StudentLevelJourney::query()
            ->with('level')
            ->where('student_id', $student->id)
            ->where('id', $journeyId)
            ->first();

        if ($journey === null) {
            throw new ApiException(ErrorCode::NOT_FOUND, 'Learning journey not found.', 404);
        }

        $maxWeek = $journey->weekNumberAt(AppClock::now());
        if ($weekNumber < 1 || $weekNumber > $maxWeek) {
            throw new ApiException(ErrorCode::FORBIDDEN, 'This week is not part of the study journey yet.', 403);
        }

        $unit = WeeklyLearning::query()
            ->with('questions.options.dimensionCodes')
            ->where('level_id', $journey->level_id)
            ->where('week_number', $weekNumber)
            ->first();

        $attempts = $unit === null
            ? collect()
            : WeeklyAssignmentAttempt::query()
                ->where('student_id', $student->id)
                ->where('weekly_learning_id', $unit->id)
                ->orderBy('attempt_number')
                ->get();

        return $this->weekPayload($student, $journey, $weekNumber, $unit, $attempts, $staffView, unlocked: true);
    }

    /**
     * @param  array<int, array{question_id: string, option_id: string}>  $answers
     */
    public function submit(StudentProfile $student, string $journeyId, int $weekNumber, array $answers): WeeklyAssignmentAttempt
    {
        $journey = StudentLevelJourney::query()
            ->where('student_id', $student->id)
            ->where('id', $journeyId)
            ->first();

        if ($journey === null || ! $journey->isCurrent()) {
            throw new ApiException(ErrorCode::FORBIDDEN, 'Assignments can only be submitted on the current level journey.', 403);
        }

        $maxWeek = $journey->weekNumberAt(AppClock::now());
        if ($weekNumber < 1 || $weekNumber > $maxWeek) {
            throw new ApiException(ErrorCode::FORBIDDEN, 'This week is not unlocked yet.', 403);
        }

        $unit = WeeklyLearning::query()
            ->with('questions.options.dimensionCodes')
            ->where('level_id', $journey->level_id)
            ->where('week_number', $weekNumber)
            ->first();

        if ($unit === null) {
            throw new ApiException(ErrorCode::NOT_FOUND, 'Weekly learning content is not available yet.', 404);
        }

        $existingCount = WeeklyAssignmentAttempt::query()
            ->where('student_id', $student->id)
            ->where('weekly_learning_id', $unit->id)
            ->count();

        if ($existingCount >= 2) {
            throw new ApiException(
                ErrorCode::ATTEMPT_LIMIT,
                'This assignment can be submitted a maximum of 2 times.',
                422,
            );
        }

        $this->assertAnswers($unit, $answers);

        $attempt = WeeklyAssignmentAttempt::query()->create([
            'student_id' => $student->id,
            'student_level_journey_id' => $journey->id,
            'weekly_learning_id' => $unit->id,
            'week_number' => $weekNumber,
            'attempt_number' => $existingCount + 1,
            'answers' => $answers,
            'video_url' => $unit->video_url,
            'submitted_at' => AppClock::now(),
        ]);
        StudentActivity::record(
            $student,
            'assignment_submitted',
            'Student completed Week '.$weekNumber.' question answers (attempt '.($existingCount + 1).')',
            related: $attempt,
        );

        return $attempt;
    }

    private function currentJourney(StudentProfile $student): ?StudentLevelJourney
    {
        return StudentLevelJourney::query()
            ->with('level')
            ->where('student_id', $student->id)
            ->whereNull('ended_at')
            ->first();
    }

    /**
     * @param  Collection<int, WeeklyAssignmentAttempt>  $attempts
     * @return array<string, mixed>
     */
    private function weekPayload(
        StudentProfile $student,
        StudentLevelJourney $journey,
        int $weekNumber,
        ?WeeklyLearning $unit,
        Collection $attempts,
        bool $staffView,
        bool $unlocked,
        bool $compact = false,
    ): array {
        $attemptCount = $attempts->count();
        $status = $attemptCount > 0 ? 'completed' : ($unit === null ? 'unavailable' : 'pending');
        $videoUrl = $attempts->last()?->video_url ?? $unit?->video_url;
        $level = $journey->level ?? $student->academicLevel;
        $curriculum = $level !== null ? CurriculumCalendar::forWeek($weekNumber, $level) : null;
        $studyDate = $journey->started_at?->copy()->addWeeks($weekNumber - 1);

        $payload = [
            'journey_id' => $journey->id,
            'level' => [
                'id' => $journey->level_id,
                'name' => $journey->level?->name,
            ],
            'week_number' => $weekNumber,
            'assignment_status' => $status,
            'attempts_used' => $attemptCount,
            'attempts_max' => 2,
            'can_submit' => $unlocked && $journey->isCurrent() && $unit !== null && $attemptCount < 2,
            'video_url' => $videoUrl,
            'has_video' => is_string($videoUrl) && $videoUrl !== '',
            'score' => null,
            'result' => $staffView && ! $compact && $unit !== null && $attempts->isNotEmpty()
                ? $this->attemptResult($unit, $attempts->last(), $weekNumber, $journey->level?->name)
                : null,
        ];

        if ($staffView) {
            $payload['study_date'] = $studyDate?->toDateString();
            $payload['month'] = $curriculum['month_name'] ?? null;
            $payload['year'] = $curriculum['year'] ?? null;
            $payload['student'] = [
                'id' => $student->id,
                'full_name' => $student->full_name,
                'current_level' => $student->academicLevel?->name,
            ];
        }

        if ($compact) {
            return $payload;
        }

        $payload['questions'] = $unit === null ? [] : $unit->questions->map(function ($question) use ($staffView) {
            return [
                'id' => $question->id,
                'question_text' => $question->question_text,
                'question_type' => $question->question_type->value,
                'display_order' => $question->display_order,
                'options' => $question->options->map(fn ($option) => [
                    'id' => $option->id,
                    'option_text' => $option->option_text,
                    'display_order' => $option->display_order,
                    'dimension_codes' => $this->whenStaff($staffView, $option->dimensionCodes
                        ->map(fn ($dimension) => $dimension->dimension_code->value)
                        ->values()
                        ->all()),
                ])->values()->all(),
            ];
        })->values()->all();

        $payload['attempts'] = $attempts->map(fn (WeeklyAssignmentAttempt $attempt) => [
            'attempt_number' => $attempt->attempt_number,
            'submitted_at' => $attempt->submitted_at?->toIso8601String(),
            'answers' => $attempt->answers,
            'video_url' => $attempt->video_url,
            'result' => $staffView && $unit !== null
                ? $this->attemptResult($unit, $attempt, $weekNumber, $journey->level?->name)
                : null,
        ])->values()->all();

        return $payload;
    }

    /**
     * @return array{id: string, assessment: array{title: string}, submitted_at: ?string, dimensions: list<array{name: string, score: int}>}
     */
    private function attemptResult(
        WeeklyLearning $unit,
        WeeklyAssignmentAttempt $attempt,
        int $weekNumber,
        ?string $levelName,
    ): array {
        $options = $unit->questions->flatMap(fn ($question) => $question->options)->keyBy('id');
        $codeLists = [];

        foreach ($attempt->answers ?? [] as $answer) {
            $option = $options->get((string) ($answer['option_id'] ?? ''));
            if ($option === null) {
                continue;
            }

            $codeLists[] = $option->dimensionCodes
                ->map(fn ($row) => $row->dimension_code)
                ->all();
        }

        $title = trim(($levelName ?? '').' · Week '.$weekNumber, ' ·');

        return [
            'id' => $attempt->id,
            'assessment' => [
                'title' => $title,
            ],
            'submitted_at' => $attempt->submitted_at?->toIso8601String(),
            'dimensions' => $this->calculateAssessmentResult->toDimensions(
                $this->calculateAssessmentResult->fromSelectedCodes($codeLists),
            ),
        ];
    }

    private function whenStaff(bool $staffView, mixed $value): mixed
    {
        return $staffView ? $value : null;
    }

    private function ctaLabel(string $action, int $week, ?string $levelName): string
    {
        $level = $levelName ?? 'your level';

        return match ($action) {
            'complete_assignment' => "Complete {$level} – Week {$week} assignment",
            'assignment_complete' => "Week {$week} assignment completed",
            'awaiting_content' => "Continue {$level} – Week {$week}",
            default => "Continue {$level}",
        };
    }

    /**
     * @param  array<int, array{question_id?: mixed, option_id?: mixed, text_answer?: mixed}>  $answers
     */
    private function assertAnswers(WeeklyLearning $unit, array $answers): void
    {
        $questionIds = $unit->questions->pluck('id')->all();
        if (count($answers) !== count($questionIds)) {
            throw new ApiException(ErrorCode::VALIDATION_ERROR, 'Answer every question before submitting.', 422);
        }

        $answered = [];
        foreach ($answers as $answer) {
            $questionId = (string) ($answer['question_id'] ?? '');
            $question = $unit->questions->firstWhere('id', $questionId);
            if ($question === null) {
                throw new ApiException(ErrorCode::VALIDATION_ERROR, 'An answer refers to an unknown question.', 422);
            }

            if ($question->isText()) {
                $text = trim((string) ($answer['text_answer'] ?? ''));
                if ($text === '') {
                    throw new ApiException(ErrorCode::VALIDATION_ERROR, 'Enter an answer for every text field question.', 422);
                }
                if (mb_strlen($text) > 250) {
                    throw new ApiException(ErrorCode::VALIDATION_ERROR, 'Text answers may be at most 250 characters.', 422);
                }
            } else {
                $optionId = (string) ($answer['option_id'] ?? '');
                if (! $question->options->contains('id', $optionId)) {
                    throw new ApiException(ErrorCode::VALIDATION_ERROR, 'An answer refers to an unknown option.', 422);
                }
            }

            $answered[] = $questionId;
        }

        if (count(array_unique($answered)) !== count($questionIds)) {
            throw new ApiException(ErrorCode::VALIDATION_ERROR, 'Answer every question before submitting.', 422);
        }
    }
}
