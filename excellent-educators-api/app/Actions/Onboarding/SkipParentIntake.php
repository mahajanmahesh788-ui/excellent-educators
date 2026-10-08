<?php

namespace App\Actions\Onboarding;

use App\Exceptions\ApiException;
use App\Models\ParentQuestion;
use App\Models\ParentResponse;
use App\Models\StudentProfile;
use App\Support\ErrorCode;

class SkipParentIntake
{
    public function execute(StudentProfile $student): ParentResponse
    {
        $existing = ParentResponse::query()->where('student_id', $student->id)->first();
        if ($existing !== null && ($existing->isCompleted() || $existing->isSkipped())) {
            throw new ApiException(ErrorCode::VALIDATION_ERROR, 'Parent intake already submitted.', 422);
        }

        if (! ParentQuestion::query()->where('is_active', true)->exists()) {
            throw new ApiException(ErrorCode::VALIDATION_ERROR, 'No parent questions are available.', 422);
        }

        if ($existing !== null) {
            $existing->answers()->delete();
            $existing->forceFill([
                'skipped_at' => now(),
                'completed_at' => null,
            ])->save();

            return $existing->fresh();
        }

        return ParentResponse::query()->create([
            'student_id' => $student->id,
            'skipped_at' => now(),
            'completed_at' => null,
        ]);
    }
}
