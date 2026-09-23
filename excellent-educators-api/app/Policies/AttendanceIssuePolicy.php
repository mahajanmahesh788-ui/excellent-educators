<?php

namespace App\Policies;

use App\Enums\PermissionName;
use App\Models\AttendanceIssue;
use App\Models\User;

class AttendanceIssuePolicy
{
    public function viewAny(User $user): bool
    {
        return $user->canAdmin(PermissionName::QueriesView) || $user->canAdmin(PermissionName::QueriesResolve);
    }

    public function view(User $user, AttendanceIssue $issue): bool
    {
        return $this->viewAny($user);
    }

    public function resolve(User $user, AttendanceIssue $issue): bool
    {
        return $user->canAdmin(PermissionName::QueriesResolve);
    }
}
