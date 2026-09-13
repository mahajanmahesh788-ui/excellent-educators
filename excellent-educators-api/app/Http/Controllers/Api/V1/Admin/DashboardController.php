<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Attendance\AttendanceService;
use App\Enums\BatchStatus;
use App\Enums\ProfileStatus;
use App\Feedback\StudentsDueForRating;
use App\Http\Controllers\Controller;
use App\Models\Batch;
use App\Models\CareerCompassLevel;
use App\Models\StudentProfile;
use App\Models\TeacherProfile;
use App\Support\ApiResponse;
use App\Support\AppClock;
use Illuminate\Http\JsonResponse;

class DashboardController extends Controller
{
    public function show(AttendanceService $attendance, StudentsDueForRating $studentsDueForRating): JsonResponse
    {
        $maxPerBatch = app(\App\Support\AppSettings::class)->maxActiveStudents();

        $activeStudents = StudentProfile::query()->where('status', ProfileStatus::Active->value)->count();
        $inactiveStudents = StudentProfile::query()->where('status', ProfileStatus::Inactive->value)->count();
        $activeTeachers = TeacherProfile::query()->where('status', ProfileStatus::Active->value)->count();
        $activeBatches = Batch::query()->where('status', BatchStatus::Active->value)->count();

        $studentsWithoutBatch = StudentProfile::query()
            ->where('status', ProfileStatus::Active->value)
            ->whereDoesntHave('activeEnrollment')
            ->count();

        $studentsWithoutMasterTeacher = StudentProfile::query()
            ->where('status', ProfileStatus::Active->value)
            ->whereDoesntHave('activeMasterTeacherAssignment')
            ->count();

        $batchesWithoutCommonTeacher = Batch::query()
            ->where('status', BatchStatus::Active->value)
            ->whereDoesntHave('activeTeacherAssignment')
            ->count();

        $fullBatches = Batch::query()
            ->where('status', BatchStatus::Active->value)
            ->withCount('activeEnrollments')
            ->get()
            ->filter(fn (Batch $batch) => $batch->active_enrollments_count >= $maxPerBatch)
            ->count();

        ['year' => $year, 'month' => $month] = AppClock::currentYearMonth();

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

        $byCareerCompass = CareerCompassLevel::query()
            ->orderBy('class_from')
            ->get()
            ->map(function (CareerCompassLevel $level): array {
                return [
                    'id' => $level->id,
                    'code' => $level->code,
                    'name' => $level->name,
                    'class_from' => $level->class_from,
                    'class_to' => $level->class_to,
                    'active_students' => StudentProfile::query()
                        ->where('career_compass_level_id', $level->id)
                        ->where('status', ProfileStatus::Active->value)
                        ->count(),
                    'active_batches' => Batch::query()
                        ->where('career_compass_level_id', $level->id)
                        ->where('status', BatchStatus::Active->value)
                        ->count(),
                ];
            })
            ->values()
            ->all();

        return ApiResponse::success('Admin dashboard fetched successfully.', [
            'counts' => [
                'active_students' => $activeStudents,
                'inactive_students' => $inactiveStudents,
                'active_teachers' => $activeTeachers,
                'active_batches' => $activeBatches,
                'students_without_batch' => $studentsWithoutBatch,
                'students_without_master_teacher' => $studentsWithoutMasterTeacher,
                'batches_without_common_teacher' => $batchesWithoutCommonTeacher,
                'full_batches' => $fullBatches,
                'students_assessment_pending' => $studentsAssessmentPending,
                'students_without_rating_this_month' => $studentsWithoutRatingThisMonth,
                ...$attendance->dashboardCounts(),
            ],
            'career_compass' => $byCareerCompass,
        ]);
    }
}
