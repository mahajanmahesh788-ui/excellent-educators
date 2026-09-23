<?php

namespace App\Actions\Feedback;

use App\Exceptions\ApiException;
use App\Models\MonthlyFeedback;
use App\Models\StudentProfile;
use App\Models\TeacherProfile;
use App\Support\ErrorCode;
use Illuminate\Support\Facades\DB;

class DeleteMonthlyFeedback
{
    public function execute(
        ?TeacherProfile $teacher,
        StudentProfile $student,
        MonthlyFeedback $feedback,
        bool $adminOverride = false,
    ): void {
        if ($feedback->student_id !== $student->id) {
            throw new ApiException(ErrorCode::NOT_FOUND, 'Feedback was not found for this student.', 404);
        }

        if (! $adminOverride) {
            if ($teacher === null) {
                throw new ApiException(ErrorCode::FORBIDDEN, 'Only the teacher who submitted this rating can delete it.', 403);
            }

            if ($feedback->master_teacher_id !== $teacher->id) {
                throw new ApiException(
                    ErrorCode::FORBIDDEN,
                    'Only the teacher who submitted this rating can delete it.',
                    403,
                );
            }

            if (! $feedback->isWithinRatingMonth()) {
                throw new ApiException(
                    ErrorCode::FEEDBACK_LOCKED,
                    'Ratings can only be deleted during the same calendar month they were submitted.',
                    422,
                );
            }
        }

        DB::transaction(function () use ($feedback): void {
            $feedback->items()->delete();
            $feedback->delete();
        });
    }
}
