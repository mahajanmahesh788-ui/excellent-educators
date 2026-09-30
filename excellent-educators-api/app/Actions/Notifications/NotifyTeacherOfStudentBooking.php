<?php

namespace App\Actions\Notifications;

use App\Enums\NotificationType;
use App\Enums\SessionBookingType;
use App\Models\SessionBooking;
use App\Models\TeacherProfile;
use App\Scheduling\SlotGrid;
use App\Support\AppClock;

class NotifyTeacherOfStudentBooking
{
    public function __construct(
        private readonly CreateUserNotification $notifications,
    ) {}

    public function booked(SessionBooking $booking): void
    {
        $booking->loadMissing(['student', 'teacher.user']);
        $teacherUser = $booking->teacher?->user;
        $student = $booking->student;
        if ($teacherUser === null || $student === null) {
            return;
        }

        $label = SessionBookingType::fromMixed($booking->type)?->label() ?? 'session';
        $when = AppClock::formatWhen($booking->date, $booking->starts_at);

        $this->notifications->safeExecute(
            $teacherUser,
            NotificationType::SessionBooked,
            'New session booked',
            "{$student->full_name} booked a {$label} with you for {$when}.",
            $this->payload($booking),
        );
    }

    public function rescheduled(
        SessionBooking $booking,
        ?TeacherProfile $previousTeacher = null,
        ?string $previousWhen = null,
    ): void {
        $booking->loadMissing(['student', 'teacher.user']);
        $student = $booking->student;
        $teacher = $booking->teacher;
        $teacherUser = $teacher?->user;
        if ($student === null || $teacherUser === null) {
            return;
        }

        $label = SessionBookingType::fromMixed($booking->type)?->label() ?? 'session';
        $when = AppClock::formatWhen($booking->date, $booking->starts_at);
        $teacherChanged = $previousTeacher !== null && $previousTeacher->id !== $teacher->id;

        if ($teacherChanged) {
            $this->notifications->safeExecute(
                $teacherUser,
                NotificationType::SessionRescheduled,
                'Session assigned to you',
                "{$student->full_name}'s {$label} was moved to you for {$when}.",
                $this->payload($booking),
            );

            $previousTeacher->loadMissing('user');
            if ($previousTeacher->user !== null) {
                $from = $previousWhen ?? 'the previous time';
                $this->notifications->safeExecute(
                    $previousTeacher->user,
                    NotificationType::SessionRescheduled,
                    'Session moved',
                    "{$student->full_name}'s {$label} ({$from}) was rescheduled to another mentor.",
                    [
                        'booking_id' => $booking->id,
                        'student_id' => $student->id,
                        'student_name' => $student->full_name,
                    ],
                );
            }

            return;
        }

        $from = $previousWhen !== null && $previousWhen !== $when
            ? " from {$previousWhen}"
            : '';

        $this->notifications->safeExecute(
            $teacherUser,
            NotificationType::SessionRescheduled,
            'Session rescheduled',
            "{$student->full_name} rescheduled their {$label}{$from} to {$when}.",
            $this->payload($booking),
        );
    }

    /**
     * @return array<string, mixed>
     */
    private function payload(SessionBooking $booking): array
    {
        return [
            'booking_id' => $booking->id,
            'student_id' => $booking->student_id,
            'student_name' => $booking->student?->full_name,
            'teacher_id' => $booking->teacher_id,
            'type' => $booking->type?->value ?? $booking->type,
            'date' => $booking->date?->toDateString(),
            'start' => SlotGrid::hmFrom($booking->starts_at),
            'link' => '/teacher/schedule/day',
        ];
    }
}
