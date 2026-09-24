<?php

namespace App\Scheduling;

use App\Models\SessionBooking;
use App\Models\TeacherProfile;
use Illuminate\Support\Collection;

class FindReplacementTeachersForBooking
{
    public function __construct(
        private readonly AvailabilityCalculator $availability,
        private readonly BookingEligibility $eligibility,
    ) {}

    /**
     * @return Collection<int, TeacherProfile>
     */
    public function execute(SessionBooking $booking, ?string $excludeTeacherId = null): Collection
    {
        $booking->loadMissing('student');
        $student = $booking->student;
        if ($student === null) {
            return collect();
        }

        $date = $booking->date?->toDateString() ?? SlotGrid::dateFrom($booking->starts_at);
        $start = SlotGrid::hmFrom($booking->starts_at);
        $exclude = $excludeTeacherId ?? $booking->teacher_id;

        return $this->eligibility->eligibleTeachers($student)
            ->filter(function (TeacherProfile $teacher) use ($exclude, $date, $start, $booking) {
                if ($teacher->id === $exclude) {
                    return false;
                }

                return $this->availability->isSlotAvailable($teacher, $date, $start, $booking->id);
            })
            ->values();
    }
}
