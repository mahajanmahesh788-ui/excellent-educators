<?php

namespace App\Actions\Notifications;

use App\Enums\NotificationType;
use App\Enums\RoleName;
use App\Exceptions\ApiException;
use App\Models\StudentProfile;
use App\Models\TeacherProfile;
use App\Models\User;
use App\Support\ErrorCode;
use Illuminate\Support\Facades\Cache;
use Throwable;

class NotifyAdminsOfStudentBookingFailure
{
    public function __construct(
        private readonly CreateUserNotification $notifications,
    ) {}

    /**
     * @param  array<string, mixed>  $context
     */
    public function execute(
        StudentProfile $student,
        ?TeacherProfile $teacher,
        Throwable $error,
        string $action = 'book',
        array $context = [],
    ): void {
        $errorCode = $error instanceof ApiException
            ? $error->errorCode
            : ErrorCode::SERVER_ERROR;
        $message = trim($error->getMessage()) !== ''
            ? $error->getMessage()
            : 'An unexpected booking error occurred.';

        // Soft-dedupe double-taps; still notify for each distinct student attempt.
        $throttleKey = implode('.', [
            'notify.student_booking_failed',
            $student->id,
            $teacher?->id ?? 'none',
            $errorCode,
            (string) ($context['date'] ?? ''),
            (string) ($context['start'] ?? ''),
            $action,
        ]);
        if (! Cache::add($throttleKey, true, now()->addSeconds(45))) {
            return;
        }

        $student->loadMissing('user');
        $teacher?->loadMissing('user');

        $studentName = $student->labeledName('A student');
        $teacherName = $teacher?->full_name ?: ($teacher?->user?->name ?? 'unknown teacher');
        $date = isset($context['date']) ? (string) $context['date'] : null;
        $start = isset($context['start']) ? (string) $context['start'] : null;
        $when = ($date !== null && $date !== '')
            ? trim($date.($start ? ' at '.$start : ''))
            : null;

        $verb = $action === 'reschedule' ? 'reschedule' : 'book';
        $title = $this->titleFor($errorCode);
        $reason = $message;
        $adminBody = $studentName.' could not '.$verb.' a session with '.$teacherName
            .($when ? ' ('.$when.')' : '')
            .'. Reason: '.$reason
            .($this->isMeetIssue($errorCode)
                ? ' Open Admin → Google Meet and reconnect if needed.'
                : '');
        $teacherBody = $studentName.' tried to '.$verb
            .($when ? ' for '.$when : '')
            .' but could not. Reason: '.$reason;

        $data = [
            'error_code' => $errorCode,
            'action' => $verb,
            'reason' => $reason,
            'student_id' => $student->id,
            'student_name' => $studentName,
            'student_code' => $student->student_code,
            'teacher_id' => $teacher?->id,
            'teacher_name' => $teacherName,
            'date' => $date,
            'start' => $start,
        ];

        try {
            User::query()
                ->role([
                    RoleName::SuperAdmin->value,
                    RoleName::OperationalAdmin->value,
                ])
                ->get()
                ->each(function (User $admin) use ($title, $adminBody, $data): void {
                    $this->notifications->execute(
                        $admin,
                        NotificationType::StudentBookingFailed,
                        $title,
                        $adminBody,
                        $data,
                    );
                });

            $this->notifications->safeExecute(
                $teacher?->user,
                NotificationType::StudentBookingFailed,
                'Student could not '.$verb,
                $teacherBody,
                $data + ['link' => '/teacher/schedule'],
            );
        } catch (Throwable) {
            // Never mask the original booking failure if notify fails.
        }
    }

    private function isMeetIssue(string $errorCode): bool
    {
        return in_array($errorCode, [
            ErrorCode::GOOGLE_NOT_CONNECTED,
            ErrorCode::MEETING_CREATE_FAILED,
        ], true);
    }

    private function titleFor(string $errorCode): string
    {
        return match ($errorCode) {
            ErrorCode::GOOGLE_NOT_CONNECTED => 'Google Meet needs reconnect',
            ErrorCode::MEETING_CREATE_FAILED => 'Student booking failed (Meet)',
            ErrorCode::SLOT_UNAVAILABLE => 'Student could not book (slot taken)',
            ErrorCode::BOOKING_OVERLAP => 'Student could not book (overlap)',
            ErrorCode::TEACHER_NOT_ELIGIBLE => 'Student could not book (teacher)',
            ErrorCode::INTRODUCTION_REQUIRED => 'Student could not book (intro required)',
            ErrorCode::MASTER_CLASS_MONTHLY_LIMIT => 'Student could not book (master class limit)',
            ErrorCode::MASTER_CLASS_LEVEL_WEEKS_INCOMPLETE => 'Student could not book (weeks incomplete)',
            default => 'Student could not book',
        };
    }
}
