<?php

namespace App\Policies;

use App\Enums\PermissionName;
use App\Models\AptitudeAssessment;
use App\Models\User;

class AptitudeAssessmentPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->isAdmin() && $user->can(PermissionName::AssessmentsView->value);
    }

    public function view(User $user, AptitudeAssessment $assessment): bool
    {
        return $this->viewAny($user);
    }

    public function create(User $user): bool
    {
        return $user->isAdmin() && $user->can(PermissionName::AssessmentsManage->value);
    }

    public function update(User $user, AptitudeAssessment $assessment): bool
    {
        return $this->create($user);
    }

    public function delete(User $user, AptitudeAssessment $assessment): bool
    {
        return $this->create($user);
    }

    public function activate(User $user, AptitudeAssessment $assessment): bool
    {
        return $this->create($user);
    }

    public function viewAttempts(User $user, AptitudeAssessment $assessment): bool
    {
        return $this->viewAny($user);
    }
}
