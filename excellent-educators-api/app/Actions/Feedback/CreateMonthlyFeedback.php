<?php

namespace App\Actions\Feedback;

use App\Enums\FeedbackTargetType;
use App\Exceptions\ApiException;
use App\Models\DevelopmentModule;
use App\Models\Dimension;
use App\Models\MonthlyFeedback;
use App\Models\MonthlyFeedbackItem;
use App\Models\Skill;
use App\Models\StudentProfile;
use App\Models\TeacherProfile;
use App\Support\AppClock;
use App\Support\ErrorCode;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class CreateMonthlyFeedback
{
    /**
     * @param  array<string, mixed>  $input
     */
    public function execute(TeacherProfile $teacher, StudentProfile $student, array $input): MonthlyFeedback
    {
        $this->assertAssigned($teacher, $student);
        $this->assertTargetsExist($input['items'] ?? []);

        $sessionDate = Carbon::parse(
            $input['session_date'] ?? AppClock::todayString(),
            config('app.timezone'),
        )->startOfDay();

        try {
            return DB::transaction(function () use ($teacher, $student, $input, $sessionDate) {
                $feedback = MonthlyFeedback::query()->create([
                    'student_id' => $student->id,
                    'master_teacher_id' => $teacher->id,
                    'year' => $sessionDate->year,
                    'month' => $sessionDate->month,
                    'session_date' => $sessionDate->toDateString(),
                    'submitted_at' => now(),
                ]);

                $this->storeItems($feedback, $input['items']);

                return $feedback->fresh(['items', 'masterTeacher', 'student']) ?? $feedback;
            });
        } catch (UniqueConstraintViolationException) {
            throw new ApiException(
                ErrorCode::FEEDBACK_DUPLICATE,
                'Monthly rating already exists for this student. Edit the existing rating instead.',
                409,
            );
        }
    }

    private function assertAssigned(TeacherProfile $teacher, StudentProfile $student): void
    {
        if (! $teacher->canAccessStudent($student)) {
            throw new ApiException(
                ErrorCode::FORBIDDEN,
                'Only the currently assigned Master Teacher can submit feedback for this student.',
                403,
            );
        }
    }

    /**
     * @param  list<array<string, mixed>>  $items
     */
    private function assertTargetsExist(array $items): void
    {
        foreach ($items as $index => $item) {
            $type = FeedbackTargetType::tryFrom((string) ($item['target_type'] ?? ''));
            $targetId = $item['target_id'] ?? null;
            $exists = match ($type) {
                FeedbackTargetType::Dimension => Dimension::query()->whereKey($targetId)->exists(),
                FeedbackTargetType::Module => DevelopmentModule::query()->whereKey($targetId)->exists(),
                FeedbackTargetType::Skill => Skill::query()->whereKey($targetId)->exists(),
                default => false,
            };

            if (! $exists) {
                throw ValidationException::withMessages([
                    "items.{$index}.target_id" => 'The selected skill, module, or dimension is invalid.',
                ]);
            }
        }
    }

    /**
     * @param  list<array<string, mixed>>  $items
     */
    public function storeItems(MonthlyFeedback $feedback, array $items): void
    {
        foreach ($items as $item) {
            MonthlyFeedbackItem::query()->create([
                'monthly_feedback_id' => $feedback->id,
                'target_type' => $item['target_type'],
                'target_id' => $item['target_id'],
                'rating' => $item['rating'],
                'positive_points' => $item['positive_points'] ?? null,
                'areas_for_improvement' => $item['areas_for_improvement'] ?? null,
                'recommended_next_action' => $item['recommended_next_action'] ?? null,
            ]);
        }
    }
}
