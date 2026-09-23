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
        if (! $this->shouldNotify($error)) {
            return;
        }

        $errorCode = $error instanceof ApiException
            ? $error->errorCode
            : ErrorCode::SERVER_ERROR;
        $message = trim($error->getMessage()) !== ''
            ? $error->getMessage()
            : 'An unexpected booking error occurred.';

        // Avoid flooding admins when many students hit the same outage.
        $throttleKey = 'admin.notify.student_booking_failed.'.$errorCode;
        if (! Cache::add($throttleKey, true, now()->addMinutes(5))) {
            return;
        }

        $student->loadMissing('user');
        $teacher?->loadMissing('user');

        $studentName = $student->full_name ?: ($student->user?->name ?? 'A student');
        $teacherName = $teacher?->full_name ?: ($teacher?->user?->name ?? 'unknown teacher');
        $date = isset($context['date']) ? (string) $context['date'] : null;
        $start = isset($context['start']) ? (string) $context['start'] : null;
        $when = ($date !== null && $date !== '')
            ? trim($date.($start ? ' at '.$start : ''))
            : null;

        $verb = $action === 'reschedule' ? 'reschedule' : 'book';
        $title = $this->titleFor($errorCode);
        $body = $studentName.' could not '.$verb.' a session with '.$teacherName
            .($when ? ' ('.$when.')' : '')
            .'. '.$message
            .($this->isMeetIssue($errorCode)
                ? ' Open Admin → Google Meet and reconnect if needed.'
                : '');

        $data = [
            'error_code' => $errorCode,
            'action' => $verb,
            'student_id' => $student->id,
            'student_name' => $studentName,
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
                ->each(function (User $admin) use ($title, $body, $data): void {
                    $this->notifications->execute(
                        $admin,
                        NotificationType::StudentBookingFailed,
                        $title,
                        $body,
                        $data,
                    );
                });
        } catch (Throwable) {
            // Never mask the original booking failure if admin notify fails.
        }
    }

    private function shouldNotify(Throwable $error): bool
    {
        if (! $error instanceof ApiException) {
            return true;
        }

        if (in_array($error->errorCode, [
            ErrorCode::GOOGLE_NOT_CONNECTED,
            ErrorCode::MEETING_CREATE_FAILED,
            ErrorCode::SERVER_ERROR,
        ], true)) {
            return true;
        }

        return $error->getStatusCode() >= 500;
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
            default => 'Student booking failed',
        };
    }
}
