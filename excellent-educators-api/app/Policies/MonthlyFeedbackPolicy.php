<?php

namespace App\Policies;

use App\Enums\PermissionName;
use App\Enums\RoleName;
use App\Models\MonthlyFeedback;
use App\Models\StudentProfile;
use App\Models\User;

class MonthlyFeedbackPolicy
{
    public function viewAnyForStudent(User $user, StudentProfile $student): bool
    {
        if ($user->isAdmin() && $user->can(PermissionName::FeedbackView->value)) {
            return true;
        }

        if ($user->hasRole(RoleName::Student) && $user->studentProfile?->id === $student->id) {
            return true;
        }

        if ($user->hasRole(RoleName::MasterTeacher)) {
            return $user->teacherProfile?->activeMasterTeacherAssignments()
                ->where('student_id', $student->id)
                ->exists() ?? false;
        }

        if ($user->hasRole(RoleName::CommonTeacher)) {
            return $this->commonTeacherAssigned($user, $student);
        }

        return false;
    }

    public function create(User $user, StudentProfile $student): bool
    {
        if ($user->isAdmin() && $user->can(PermissionName::FeedbackManage->value)) {
            return $student->activeMasterTeacherAssignment !== null;
        }

        if (! $user->hasRole(RoleName::MasterTeacher)) {
            return false;
        }

        return $user->teacherProfile?->activeMasterTeacherAssignments()
            ->where('student_id', $student->id)
            ->exists() ?? false;
    }

    public function update(User $user, MonthlyFeedback $feedback): bool
    {
        if ($user->isAdmin() && $user->can(PermissionName::FeedbackManage->value)) {
            return true;
        }

        if (! $user->hasRole(RoleName::MasterTeacher)) {
            return false;
        }

        $teacher = $user->teacherProfile;
        if ($teacher === null || $feedback->master_teacher_id !== $teacher->id) {
            return false;
        }

        if (! $teacher->activeMasterTeacherAssignments()->where('student_id', $feedback->student_id)->exists()) {
            return false;
        }

        return $feedback->isEditable();
    }

    public function delete(User $user, MonthlyFeedback $feedback): bool
    {
        if ($user->isAdmin() && $user->can(PermissionName::FeedbackManage->value)) {
            return true;
        }

        if (! $user->hasRole(RoleName::MasterTeacher)) {
            return false;
        }

        $teacher = $user->teacherProfile;
        if ($teacher === null || $feedback->master_teacher_id !== $teacher->id) {
            return false;
        }

        if (! $teacher->activeMasterTeacherAssignments()->where('student_id', $feedback->student_id)->exists()) {
            return false;
        }

        return $feedback->isDeletable();
    }

    private function commonTeacherAssigned(User $user, StudentProfile $student): bool
    {
        $teacher = $user->teacherProfile;
        if ($teacher === null) {
            return false;
        }

        $student->loadMissing('activeEnrollment');
        $batchId = $student->activeEnrollment?->batch_id;
        if ($batchId === null) {
            return false;
        }

        return $teacher->activeBatchAssignments()->where('batch_id', $batchId)->exists();
    }
}
