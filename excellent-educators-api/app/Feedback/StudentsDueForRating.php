<?php

namespace App\Feedback;

use App\Enums\SessionBookingStatus;
use App\Enums\SessionBookingType;
use App\Models\SessionBooking;
use App\Models\TeacherProfile;
use App\Support\AppClock;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Carbon;
use Illuminate\Support\Collection;

class StudentsDueForRating
{
    /**
     * Students on this teacher's roster who completed a Master Class this month
     * with no attendance complaint (those get another chance instead).
     *
     * @return Collection<int, string>
     */
    public function idsFor(TeacherProfile $teacher, int $year, int $month): Collection
    {
        $roster = $teacher->rosterStudentIds();
        if ($roster->isEmpty()) {
            return collect();
        }

        return $this->dueQuery($year, $month)
            ->where('teacher_id', $teacher->id)
            ->whereIn('student_id', $roster)
            ->distinct()
            ->pluck('student_id')
            ->values();
    }

    /**
     * Students with a completed Master Class this month and no attendance complaint.
     *
     * @return Collection<int, string>
     */
    public function idsThisMonth(int $year, int $month): Collection
    {
        return $this->dueQuery($year, $month)
            ->distinct()
            ->pluck('student_id')
            ->values();
    }

    private function dueQuery(int $year, int $month): Builder
    {
        $start = Carbon::create($year, $month, 1, 0, 0, 0, config('app.timezone'))->toDateString();
        $end = Carbon::create($year, $month, 1, 0, 0, 0, config('app.timezone'))->endOfMonth()->toDateString();

        return SessionBooking::query()
            ->where('type', SessionBookingType::MasterClass)
            ->where('status', '!=', SessionBookingStatus::Cancelled->value)
            ->whereBetween('date', [$start, $end])
            ->where('ends_at', '<=', AppClock::now())
            ->whereDoesntHave('attendanceIssues');
    }
}
