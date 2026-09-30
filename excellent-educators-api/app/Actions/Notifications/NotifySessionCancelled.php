<?php

namespace App\Actions\Notifications;

use App\Enums\NotificationType;
use App\Enums\SessionBookingType;
use App\Models\SessionBooking;
use App\Scheduling\SlotGrid;
use App\Support\AppClock;

class NotifySessionCancelled
{
    public function __construct(
        private readonly CreateUserNotification $notifications,
    ) {}

    public function execute(SessionBooking $booking): void
    {
        $booking->loadMissing(['student.user', 'teacher.user']);
        $label = SessionBookingType::fromMixed($booking->type)?->label() ?? 'session';
        $when = AppClock::formatWhen($booking->date, $booking->starts_at);
        $data = [
            'booking_id' => $booking->id,
            'student_id' => $booking->student_id,
            'teacher_id' => $booking->teacher_id,
            'type' => $booking->type?->value ?? $booking->type,
            'date' => $booking->date?->toDateString(),
            'start' => SlotGrid::hmFrom($booking->starts_at),
        ];

        $this->notifications->safeExecute(
            $booking->student?->user,
            NotificationType::SessionCancelled,
            'Session cancelled',
            "Your {$label} scheduled for {$when} was cancelled.",
            array_merge($data, ['link' => '/student/bookings']),
        );

        $studentName = $booking->student?->full_name ?? 'A student';
        $this->notifications->safeExecute(
            $booking->teacher?->user,
            NotificationType::SessionCancelled,
            'Session cancelled',
            "{$studentName}'s {$label} scheduled for {$when} was cancelled.",
            array_merge($data, ['link' => '/teacher/schedule/day']),
        );
    }
}
