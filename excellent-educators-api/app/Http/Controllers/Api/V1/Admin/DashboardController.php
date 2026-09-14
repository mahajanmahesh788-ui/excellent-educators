<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Actions\Admin\BuildAdminAcademySnapshot;
use App\Attendance\AttendanceService;
use App\Enums\BatchStatus;
use App\Enums\ProfileStatus;
use App\Feedback\StudentsDueForRating;
use App\Http\Controllers\Controller;
use App\Models\Batch;
use App\Models\StudentProfile;
use App\Models\TeacherProfile;
use App\Support\ApiResponse;
use App\Support\AppClock;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function show(Request $request, AttendanceService $attendance, StudentsDueForRating $studentsDueForRating, BuildAdminAcademySnapshot $academySnapshot): JsonResponse
    {
        $yearInput = $request->query('year');
        $monthInput = $request->query('month');

        ['year' => $currentYear, 'month' => $currentMonth] = AppClock::currentYearMonth();
        $year = $yearInput !== null && is_numeric($yearInput) ? (int) $yearInput : $currentYear;
        $month = $monthInput !== null && is_numeric($monthInput) ? (int) $monthInput : $currentMonth;
        $allMonths = $monthInput === 'all';
        $filterYear = $allMonths ? null : $year;
        $filterMonth = $allMonths ? null : $month;

        $maxPerBatch = app(\App\Support\AppSettings::class)->maxActiveStudents();

        $activeStudents = StudentProfile::query()
            ->where('status', ProfileStatus::Active->value)
            ->count();

        $inactiveStudents = StudentProfile::query()
            ->where('status', ProfileStatus::Inactive->value)
            ->count();

        $activeTeachers = TeacherProfile::query()->where('status', ProfileStatus::Active->value)->count();

        $activeBatches = Batch::query()
            ->where('status', BatchStatus::Active->value)
            ->count();

        $studentsWithoutBatch = StudentProfile::query()
            ->where('status', ProfileStatus::Active->value)
            ->whereDoesntHave('activeEnrollment')
            ->count();

        $fullBatches = Batch::query()
            ->where('status', BatchStatus::Active->value)
            ->withCount('activeEnrollments')
            ->get()
            ->filter(fn (Batch $batch) => $batch->active_enrollments_count >= $maxPerBatch)
            ->count();

        $studentsAssessmentPending = StudentProfile::query()
            ->where('status', ProfileStatus::Active->value)
            ->whereDoesntHave('latestAptitudeAssessmentResult')
            ->count();

        $dueIds = $studentsDueForRating->idsThisMonth($year, $month);
        $studentsWithoutRatingThisMonth = $dueIds->isEmpty()
            ? 0
            : StudentProfile::query()
                ->where('status', ProfileStatus::Active->value)
                ->whereIn('id', $dueIds)
                ->whereDoesntHave('monthlyFeedbacks', fn ($feedback) => $feedback
                    ->where('year', $year)
                    ->where('month', $month))
                ->count();

        $snapshot = $academySnapshot->execute($filterYear, $filterMonth);

        return ApiResponse::success('Admin dashboard fetched successfully.', [
            'counts' => [
                'active_students' => $activeStudents,
                'inactive_students' => $inactiveStudents,
                'active_teachers' => $activeTeachers,
                'active_batches' => $activeBatches,
                'students_without_batch' => $studentsWithoutBatch,
                'full_batches' => $fullBatches,
                'students_assessment_pending' => $studentsAssessmentPending,
                'students_without_rating_this_month' => $studentsWithoutRatingThisMonth,
                ...$attendance->dashboardCounts($filterYear, $filterMonth),
                ...$snapshot['counts'],
            ],
            'by_level' => $snapshot['by_level'],
            'top_students' => $snapshot['top_students'],
            'top_teachers' => $snapshot['top_teachers'],
        ]);
    }
}
