<?php

namespace App\Policies;

use App\Models\AttendanceIssue;
use App\Models\User;

class AttendanceIssuePolicy
{
    public function viewAny(User $user): bool
    {
        return $user->isAdmin();
    }

    public function view(User $user, AttendanceIssue $issue): bool
    {
        return $user->isAdmin();
    }

    public function resolve(User $user, AttendanceIssue $issue): bool
    {
        return $user->isAdmin();
    }
}
