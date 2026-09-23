<?php

namespace App\Policies;

use App\Enums\PermissionName;
use App\Enums\RoleName;
use App\Models\SessionBooking;
use App\Models\StudentProfile;
use App\Models\User;

class LearningJournalPolicy
{
    public function view(User $user, StudentProfile $student): bool
    {
        if ($user->canAdmin(PermissionName::StudentsView)) {
            return true;
        }

        if ($user->hasRole(RoleName::Student) && $user->studentProfile?->id === $student->id) {
            return true;
        }

        if ($user->hasRole(RoleName::MasterTeacher)) {
            return $this->teacherMayView($user, $student);
        }

        return false;
    }

    public function submit(User $user, StudentProfile $student): bool
    {
        return $user->hasRole(RoleName::Student) && $user->studentProfile?->id === $student->id;
    }

    public function manageContent(User $user): bool
    {
        return $user->canAdmin(PermissionName::LevelsManage);
    }

    public function promote(User $user): bool
    {
        return $user->canAdmin(PermissionName::StudentsPromote) || $user->hasRole(RoleName::MasterTeacher);
    }

    public function promoteStudent(User $user, StudentProfile $student): bool
    {
        if ($user->canAdmin(PermissionName::StudentsPromote)) {
            return true;
        }

        if ($user->hasRole(RoleName::MasterTeacher)) {
            return $user->teacherProfile?->canAccessStudent($student) ?? false;
        }

        return false;
    }

    private function teacherMayView(User $user, StudentProfile $student): bool
    {
        $teacher = $user->teacherProfile;
        if ($teacher === null) {
            return false;
        }
        if ($teacher->canAccessStudent($student)) {
            return true;
        }

        $student->loadMissing('activeEnrollment');
        $batchId = $student->activeEnrollment?->batch_id;
        if ($batchId !== null && $teacher->activeBatchAssignments()->where('batch_id', $batchId)->exists()) {
            return true;
        }

        return SessionBooking::query()
            ->where('teacher_id', $teacher->id)
            ->where('student_id', $student->id)
            ->exists();
    }
}
