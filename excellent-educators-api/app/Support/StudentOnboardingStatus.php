<?php

namespace App\Support;

use App\Enums\RoleName;
use App\Models\InterestQuestion;
use App\Models\InterestResponse;
use App\Models\ParentQuestion;
use App\Models\ParentResponse;
use App\Models\StudentProfile;
use App\Models\User;

final class StudentOnboardingStatus
{
    /**
     * @return array{
     *   must_complete_interest_profile: bool,
     *   must_complete_parent_intake: bool,
     *   interest_profile_completed: bool,
     *   parent_intake_completed: bool,
     *   parent_intake_skipped: bool
     * }
     */
    public static function forUser(User $user): array
    {
        if (! $user->hasRole(RoleName::Student->value)) {
            return [
                'must_complete_interest_profile' => false,
                'must_complete_parent_intake' => false,
                'interest_profile_completed' => false,
                'parent_intake_completed' => false,
                'parent_intake_skipped' => false,
            ];
        }

        $student = $user->studentProfile;
        if ($student === null) {
            return [
                'must_complete_interest_profile' => false,
                'must_complete_parent_intake' => false,
                'interest_profile_completed' => false,
                'parent_intake_completed' => false,
                'parent_intake_skipped' => false,
            ];
        }

        return self::forStudent($student);
    }

    /**
     * @return array{
     *   must_complete_interest_profile: bool,
     *   must_complete_parent_intake: bool,
     *   interest_profile_completed: bool,
     *   parent_intake_completed: bool,
     *   parent_intake_skipped: bool
     * }
     */
    public static function forStudent(StudentProfile $student): array
    {
        $hasInterestQuestions = InterestQuestion::query()->where('is_active', true)->exists();
        $hasParentQuestions = ParentQuestion::query()->where('is_active', true)->exists();

        $interestResponse = InterestResponse::query()->where('student_id', $student->id)->first();
        $parentResponse = ParentResponse::query()->where('student_id', $student->id)->first();

        $interestCompleted = $interestResponse !== null;
        $parentCompleted = $parentResponse?->isCompleted() ?? false;
        $parentSkipped = $parentResponse?->isSkipped() ?? false;
        $parentDone = $parentCompleted || $parentSkipped;

        return [
            'must_complete_interest_profile' => $hasInterestQuestions && ! $interestCompleted,
            'must_complete_parent_intake' => $hasParentQuestions && ! $parentDone,
            'interest_profile_completed' => $interestCompleted,
            'parent_intake_completed' => $parentCompleted,
            'parent_intake_skipped' => $parentSkipped,
        ];
    }
}
