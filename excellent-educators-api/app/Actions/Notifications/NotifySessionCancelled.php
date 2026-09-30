<?php

namespace App\Actions\Notifications;

use App\Enums\NotificationType;
use App\Enums\SessionBookingType;
use App\Models\SessionBooking;
use App\Scheduling\SlotGrid;
use App\Support\AppClock;
use Illuminate\Support\Carbon;
use Throwable;

class NotifySessionCancelled
{
    public function __construct(
        private readonly CreateUserNotification $notifications,
    ) {}

    public function execute(SessionBooking $booking): void
    {
        try {
            $booking->loadMissing(['student.user', 'teacher.user']);
            $label = SessionBookingType::fromMixed($booking->type)?->label() ?? 'session';
            $when = $this->whenLabel($booking);
            $data = [
                'booking_id' => $booking->id,
                'student_id' => $booking->student_id,
                'teacher_id' => $booking->teacher_id,
                'type' => $booking->type?->value ?? $booking->type,
                'date' => $booking->date?->toDateString(),
                'start' => SlotGrid::hmFrom($booking->starts_at),
            ];

            $studentUser = $booking->student?->user;
            if ($studentUser !== null) {
                $this->notifications->execute(
                    $studentUser,
                    NotificationType::SessionCancelled,
                    'Session cancelled',
                    "Your {$label} scheduled for {$when} was cancelled.",
                    array_merge($data, ['link' => '/student/bookings']),
                );
            }

            $teacherUser = $booking->teacher?->user;
            if ($teacherUser !== null) {
                $studentName = $booking->student?->full_name ?? 'A student';
                $this->notifications->execute(
                    $teacherUser,
                    NotificationType::SessionCancelled,
                    'Session cancelled',
                    "{$studentName}'s {$label} scheduled for {$when} was cancelled.",
                    array_merge($data, ['link' => '/teacher/schedule/day']),
                );
            }
        } catch (Throwable) {
            // Cancellation must succeed even if notify fails.
        }
    }

    private function whenLabel(SessionBooking $booking): string
    {
        $date = $booking->date?->toDateString();
        $displayDate = $date !== null ? Carbon::parse($date)->format('d-M-Y') : '';
        $time = AppClock::formatTime($booking->starts_at);

        return trim($displayDate.($time !== '' ? ' at '.$time : '')) ?: 'the scheduled time';
    }
}
