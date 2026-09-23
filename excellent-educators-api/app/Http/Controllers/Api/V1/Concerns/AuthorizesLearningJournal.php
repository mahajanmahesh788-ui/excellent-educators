<?php

namespace App\Http\Controllers\Api\V1\Concerns;

use App\Enums\PermissionName;
use App\Enums\RoleName;
use App\Exceptions\ApiException;
use App\Models\StudentProfile;
use App\Policies\LearningJournalPolicy;
use App\Support\ErrorCode;
use Illuminate\Http\Request;

trait AuthorizesLearningJournal
{
    protected function learningPolicy(): LearningJournalPolicy
    {
        return new LearningJournalPolicy;
    }

    protected function assertCanViewJournal(Request $request, StudentProfile $student): void
    {
        if (! $this->learningPolicy()->view($request->user(), $student)) {
            throw new ApiException(ErrorCode::FORBIDDEN, 'You cannot view this learning journal.', 403);
        }
    }

    protected function assertCanSubmitJournal(Request $request, StudentProfile $student): void
    {
        if (! $this->learningPolicy()->submit($request->user(), $student)) {
            throw new ApiException(ErrorCode::FORBIDDEN, 'You cannot submit this assignment.', 403);
        }
    }

    protected function assertCanManageWeeklyLearning(Request $request): void
    {
        if (! $this->learningPolicy()->manageContent($request->user())) {
            throw new ApiException(ErrorCode::FORBIDDEN, 'You cannot manage weekly learning.', 403);
        }
    }

    protected function assertCanPromote(Request $request, StudentProfile $student): void
    {
        if (! $this->learningPolicy()->promoteStudent($request->user(), $student)) {
            throw new ApiException(ErrorCode::FORBIDDEN, 'You cannot promote this student.', 403);
        }
    }

    protected function staffView(Request $request): bool
    {
        $user = $request->user();

        return $user !== null && ($user->canAdmin(PermissionName::StudentsView) || $user->hasRole(RoleName::MasterTeacher));
    }
}
