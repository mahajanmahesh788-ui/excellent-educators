<?php

namespace App\Scheduling;

use App\Enums\SessionBookingStatus;
use App\Models\SessionBooking;
use App\Models\TeacherLeave;
use App\Models\TeacherProfile;
use Illuminate\Support\Collection;

class FindBookingsAffectedByLeave
{
    /**
     * @param  Collection<int, TeacherLeave>|iterable<int, TeacherLeave>  $leaves
     * @return Collection<int, SessionBooking>
     */
    public function execute(iterable $leaves): Collection
    {
        $leaves = Collection::make($leaves);
        if ($leaves->isEmpty()) {
            return collect();
        }

        /** @var TeacherLeave $primary */
        $primary = $leaves->first();
        $teacherId = $primary->teacher_id;
        $date = $primary->date?->toDateString();
        if ($teacherId === null || $date === null) {
            return collect();
        }

        $bookings = SessionBooking::query()
            ->with(['student', 'teacher'])
            ->where('teacher_id', $teacherId)
            ->whereDate('date', $date)
            ->where('status', SessionBookingStatus::Scheduled->value)
            ->orderBy('starts_at')
            ->get();

        return $bookings->filter(function (SessionBooking $booking) use ($leaves) {
            $bookingStart = SlotGrid::parseHm(SlotGrid::hmFrom($booking->starts_at));
            $bookingEnd = SlotGrid::parseHm(SlotGrid::hmFrom($booking->ends_at));

            foreach ($leaves as $leave) {
                $leaveStart = SlotGrid::parseHm(substr((string) $leave->start_time, 0, 5));
                $leaveEnd = SlotGrid::parseHm(substr((string) $leave->end_time, 0, 5));
                if ($bookingStart < $leaveEnd && $leaveStart < $bookingEnd) {
                    return true;
                }
            }

            return false;
        })->values();
    }

    /**
     * @param  list<string>  $starts
     * @return Collection<int, SessionBooking>
     */
    public function forStarts(TeacherProfile $teacher, string $date, array $starts): Collection
    {
        if ($starts === []) {
            return collect();
        }

        $wanted = array_flip($starts);
        $bookings = SessionBooking::query()
            ->with(['student', 'teacher'])
            ->where('teacher_id', $teacher->id)
            ->whereDate('date', $date)
            ->where('status', SessionBookingStatus::Scheduled->value)
            ->orderBy('starts_at')
            ->get();

        return $bookings->filter(function (SessionBooking $booking) use ($wanted) {
            $start = SlotGrid::hmFrom($booking->starts_at);

            return isset($wanted[$start]);
        })->values();
    }
}
