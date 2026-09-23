<?php

namespace App\Actions\Feedback;

use App\Exceptions\ApiException;
use App\Models\MonthlyFeedback;
use App\Models\StudentProfile;
use App\Models\TeacherProfile;
use App\Support\ErrorCode;
use Illuminate\Support\Facades\DB;

class UpdateMonthlyFeedback
{
    public function __construct(private readonly CreateMonthlyFeedback $createMonthlyFeedback) {}

    /**
     * @param  array<string, mixed>  $input
     */
    public function execute(
        TeacherProfile $teacher,
        StudentProfile $student,
        MonthlyFeedback $feedback,
        array $input,
        bool $adminOverride = false,
    ): MonthlyFeedback {
        if ($feedback->student_id !== $student->id) {
            throw new ApiException(ErrorCode::NOT_FOUND, 'Feedback was not found for this student.', 404);
        }

        if (! $adminOverride) {
            if ($feedback->master_teacher_id !== $teacher->id) {
                throw new ApiException(
                    ErrorCode::FORBIDDEN,
                    'Only the teacher who submitted this rating can update it.',
                    403,
                );
            }

            if (! $feedback->isEditable()) {
                throw new ApiException(
                    ErrorCode::FEEDBACK_LOCKED,
                    'Ratings can only be edited during the same calendar month they were submitted.',
                    422,
                );
            }
        }

        return DB::transaction(function () use ($feedback, $input, $adminOverride) {
            $locked = MonthlyFeedback::query()->whereKey($feedback->id)->lockForUpdate()->firstOrFail();

            if (! $adminOverride && ! $locked->isEditable()) {
                throw new ApiException(
                    ErrorCode::FEEDBACK_LOCKED,
                    'Ratings can only be edited during the same calendar month they were submitted.',
                    422,
                );
            }

            $this->createMonthlyFeedback->assertDimensionItems($input['items'] ?? []);
            $locked->items()->delete();
            $this->createMonthlyFeedback->storeItems($locked, $input['items']);
            $locked->update([
                'positive_points' => $input['positive_points'] ?? $locked->positive_points,
                'areas_for_improvement' => array_key_exists('areas_for_improvement', $input)
                    ? $input['areas_for_improvement']
                    : $locked->areas_for_improvement,
                'discussed_in_class' => array_key_exists('discussed_in_class', $input)
                    ? $input['discussed_in_class']
                    : $locked->discussed_in_class,
            ]);
            $locked->touch();

            return $locked->fresh(['items', 'masterTeacher', 'student']) ?? $locked;
        });
    }
}
