<?php

namespace App\Actions\Notifications;

use App\Enums\NotificationType;
use App\Models\Batch;
use App\Models\StudentProfile;
use App\Models\TeacherProfile;
use App\Models\User;

class DispatchAssignmentNotifications
{
    public function __construct(
        private readonly CreateUserNotification $createUserNotification,
    ) {}

    public function masterTeacherAssigned(
        StudentProfile $student,
        TeacherProfile $teacher,
        ?TeacherProfile $previousTeacher = null,
    ): void {
        $student->loadMissing('user');
        $teacher->loadMissing('user');

        $studentType = $previousTeacher === null
            ? NotificationType::MasterTeacherAssigned
            : NotificationType::MasterTeacherChanged;

        $studentBody = $previousTeacher === null
            ? "{$teacher->full_name} is now your Master Teacher."
            : "Your Master Teacher changed from {$previousTeacher->full_name} to {$teacher->full_name}.";

        $this->notify(
            $student->user,
            $studentType,
            'Master Teacher update',
            $studentBody,
            [
                'student_id' => $student->id,
                'teacher_id' => $teacher->id,
                'previous_teacher_id' => $previousTeacher?->id,
            ],
        );

        $teacherBody = $previousTeacher === null
            ? "{$student->full_name} ({$student->student_code}) was assigned to you as a mentee."
            : "{$student->full_name} ({$student->student_code}) was reassigned to you as a mentee.";

        $this->notify(
            $teacher->user,
            NotificationType::MasterTeacherAssigned,
            'New mentee assigned',
            $teacherBody,
            [
                'student_id' => $student->id,
                'teacher_id' => $teacher->id,
            ],
        );

        if ($previousTeacher !== null && $previousTeacher->id !== $teacher->id) {
            $previousTeacher->loadMissing('user');
            $this->notify(
                $previousTeacher->user,
                NotificationType::MasterTeacherRemoved,
                'Mentee reassigned',
                "{$student->full_name} ({$student->student_code}) is no longer assigned to you.",
                [
                    'student_id' => $student->id,
                    'teacher_id' => $previousTeacher->id,
                ],
            );
        }
    }

    public function masterTeacherRemoved(StudentProfile $student, TeacherProfile $previousTeacher): void
    {
        $student->loadMissing('user');
        $previousTeacher->loadMissing('user');

        $this->notify(
            $student->user,
            NotificationType::MasterTeacherRemoved,
            'Master Teacher removed',
            'Your Master Teacher assignment was removed.',
            ['student_id' => $student->id],
        );

        $this->notify(
            $previousTeacher->user,
            NotificationType::MasterTeacherRemoved,
            'Mentee removed',
            "{$student->full_name} ({$student->student_code}) is no longer assigned to you.",
            [
                'student_id' => $student->id,
                'teacher_id' => $previousTeacher->id,
            ],
        );
    }

    public function commonTeacherAssigned(
        Batch $batch,
        TeacherProfile $teacher,
        ?TeacherProfile $previousTeacher = null,
    ): void {
        $batch->loadMissing('activeEnrollments.student.user');
        $teacher->loadMissing('user');

        $isChange = $previousTeacher !== null && $previousTeacher->id !== $teacher->id;

        $this->notify(
            $teacher->user,
            NotificationType::CommonTeacherAssigned,
            $isChange ? 'Batch reassigned to you' : 'Batch assigned to you',
            $isChange
                ? "You are now the Common Teacher for {$batch->name}."
                : "You were assigned as Common Teacher for {$batch->name}.",
            [
                'batch_id' => $batch->id,
                'teacher_id' => $teacher->id,
            ],
        );

        if ($isChange) {
            $previousTeacher->loadMissing('user');
            $this->notify(
                $previousTeacher->user,
                NotificationType::CommonTeacherRemoved,
                'Batch reassigned',
                "You are no longer the Common Teacher for {$batch->name}.",
                [
                    'batch_id' => $batch->id,
                    'teacher_id' => $previousTeacher->id,
                ],
            );
        }

        foreach ($batch->activeEnrollments as $enrollment) {
            $student = $enrollment->student;
            if ($student === null) {
                continue;
            }
            $student->loadMissing('user');

            $body = $isChange
                ? "Your Common Teacher for {$batch->name} is now {$teacher->full_name}."
                : "{$teacher->full_name} is now your Common Teacher for {$batch->name}.";

            $this->notify(
                $student->user,
                $isChange ? NotificationType::CommonTeacherChanged : NotificationType::CommonTeacherAssigned,
                'Common Teacher update',
                $body,
                [
                    'batch_id' => $batch->id,
                    'student_id' => $student->id,
                    'teacher_id' => $teacher->id,
                ],
            );
        }
    }

    public function commonTeacherRemoved(Batch $batch, TeacherProfile $previousTeacher): void
    {
        $batch->loadMissing('activeEnrollments.student.user');
        $previousTeacher->loadMissing('user');

        $this->notify(
            $previousTeacher->user,
            NotificationType::CommonTeacherRemoved,
            'Batch assignment removed',
            "You are no longer the Common Teacher for {$batch->name}.",
            [
                'batch_id' => $batch->id,
                'teacher_id' => $previousTeacher->id,
            ],
        );

        foreach ($batch->activeEnrollments as $enrollment) {
            $student = $enrollment->student;
            if ($student === null) {
                continue;
            }
            $student->loadMissing('user');

            $this->notify(
                $student->user,
                NotificationType::CommonTeacherRemoved,
                'Common Teacher removed',
                "The Common Teacher for {$batch->name} was removed.",
                [
                    'batch_id' => $batch->id,
                    'student_id' => $student->id,
                ],
            );
        }
    }

    public function studentEnrolled(Batch $batch, StudentProfile $student): void
    {
        $student->loadMissing('user');
        $batch->loadMissing('activeTeacherAssignment.teacher.user');

        $this->notify(
            $student->user,
            NotificationType::StudentEnrolledInBatch,
            'Batch enrollment',
            "You were enrolled in {$batch->name}.",
            [
                'batch_id' => $batch->id,
                'student_id' => $student->id,
            ],
        );

        $commonTeacher = $batch->activeTeacherAssignment?->teacher;
        if ($commonTeacher !== null) {
            $commonTeacher->loadMissing('user');
            $this->notify(
                $commonTeacher->user,
                NotificationType::StudentEnrolledInBatch,
                'New batch student',
                "{$student->full_name} ({$student->student_code}) was enrolled in {$batch->name}.",
                [
                    'batch_id' => $batch->id,
                    'student_id' => $student->id,
                    'teacher_id' => $commonTeacher->id,
                ],
            );
        }
    }

    public function studentUnenrolled(Batch $batch, StudentProfile $student): void
    {
        $student->loadMissing('user');
        $batch->loadMissing('activeTeacherAssignment.teacher.user');

        $this->notify(
            $student->user,
            NotificationType::StudentUnenrolledFromBatch,
            'Batch update',
            "You were removed from {$batch->name}.",
            [
                'batch_id' => $batch->id,
                'student_id' => $student->id,
            ],
        );

        $commonTeacher = $batch->activeTeacherAssignment?->teacher;
        if ($commonTeacher !== null) {
            $commonTeacher->loadMissing('user');
            $this->notify(
                $commonTeacher->user,
                NotificationType::StudentUnenrolledFromBatch,
                'Student removed from batch',
                "{$student->full_name} ({$student->student_code}) was removed from {$batch->name}.",
                [
                    'batch_id' => $batch->id,
                    'student_id' => $student->id,
                    'teacher_id' => $commonTeacher->id,
                ],
            );
        }
    }

    /**
     * @param  array<string, mixed>  $data
     */
    private function notify(
        ?User $user,
        NotificationType $type,
        string $title,
        string $body,
        array $data = [],
    ): void {
        if ($user === null) {
            return;
        }

        $this->createUserNotification->execute($user, $type, $title, $body, $data);
    }
}
