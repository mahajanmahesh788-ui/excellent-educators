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
            $assigned = $teacher->activeMasterTeacherAssignments()
                ->where('student_id', $student->id)
                ->exists();

            if (! $assigned || $feedback->master_teacher_id !== $teacher->id) {
                throw new ApiException(
                    ErrorCode::FORBIDDEN,
                    'Only the Master Teacher who submitted this rating can update it.',
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

            $locked->items()->delete();
            $this->createMonthlyFeedback->storeItems($locked, $input['items']);
            $locked->touch();

            return $locked->fresh(['items', 'masterTeacher', 'student']) ?? $locked;
        });
    }
}
