<?php

namespace App\Actions\Admin;

use App\Enums\ProfileStatus;
use App\Enums\SessionBookingStatus;
use App\Enums\SessionBookingType;
use App\Models\AcademicLevel;
use App\Models\MasterTeacherAssignment;
use App\Models\MonthlyFeedbackItem;
use App\Models\SessionBooking;
use App\Models\StudentLevelJourney;
use App\Models\StudentProfile;
use App\Models\TeacherProfile;
use App\Support\AppClock;

class BuildAdminAcademySnapshot
{
    /**
     * @return array<string, mixed>
     */
    public function execute(?int $year = null, ?int $month = null): array
    {
        $bookingScope = function ($query) use ($year, $month): void {
            if ($year !== null && $month !== null) {
                $query->whereYear('date', $year)->whereMonth('date', $month);
            }
        };

        $interviews = SessionBooking::query()
            ->where('type', SessionBookingType::IntroductionCall->value)
            ->where('status', '!=', SessionBookingStatus::Cancelled->value)
            ->where($bookingScope)
            ->count();
        $masterClasses = SessionBooking::query()
            ->where('type', SessionBookingType::MasterClass->value)
            ->where('status', '!=', SessionBookingStatus::Cancelled->value)
            ->where($bookingScope)
            ->count();
        $promotedStudents = StudentProfile::query()
            ->where('status', ProfileStatus::Active->value)
            ->whereHas('levelJourneys', fn ($query) => $query->whereNotNull('ended_at'))
            ->count();

        return [
            'counts' => [
                'total_students' => StudentProfile::query()->count(),
                'interviews' => $interviews,
                'master_classes' => $masterClasses,
                'promoted_students' => $promotedStudents,
            ],
            'by_level' => $this->byLevel(),
            'top_students' => $this->topStudents(),
            'top_teachers' => $this->topTeachers($year, $month),
        ];
    }

    /**
     * @return list<array<string, mixed>>
     */
    private function byLevel(): array
    {
        $levels = AcademicLevel::query()
            ->with(['batches' => fn ($query) => $query->withCount('activeEnrollments')->orderBy('name')])
            ->withCount(['students as active_student_count' => fn ($query) => $query->where('status', ProfileStatus::Active->value)])
            ->orderBy('name')
            ->get();

        return $levels->map(function (AcademicLevel $level): array {
            return [
                'id' => $level->id,
                'name' => $level->name,
                'student_count' => (int) $level->active_student_count,
                'batches' => $level->batches->map(fn ($batch) => [
                    'id' => $batch->id,
                    'name' => $batch->name,
                    'student_count' => (int) $batch->active_enrollments_count,
                ])->values()->all(),
            ];
        })->values()->all();
    }

    /**
     * @return list<array<string, mixed>>
     */
    private function topStudents(): array
    {
        $averages = MonthlyFeedbackItem::query()
            ->selectRaw('monthly_feedbacks.student_id as student_id, avg(monthly_feedback_items.rating) as rating_average, count(*) as rating_items')
            ->join('monthly_feedbacks', 'monthly_feedbacks.id', '=', 'monthly_feedback_items.monthly_feedback_id')
            ->groupBy('monthly_feedbacks.student_id')
            ->orderByDesc('rating_average')
            ->limit(40)
            ->get()
            ->keyBy('student_id');

        if ($averages->isEmpty()) {
            return $this->longestStudents();
        }

        $students = StudentProfile::query()
            ->with('academicLevel')
            ->whereIn('id', $averages->keys())
            ->where('status', ProfileStatus::Active->value)
            ->get()
            ->keyBy('id');

        $masterCounts = SessionBooking::query()
            ->selectRaw('student_id, count(*) as total')
            ->whereIn('student_id', $averages->keys())
            ->where('type', SessionBookingType::MasterClass->value)
            ->where('status', SessionBookingStatus::Completed->value)
            ->groupBy('student_id')
            ->pluck('total', 'student_id');

        return $averages
            ->map(function ($row) use ($students, $masterCounts): ?array {
                $student = $students->get($row->student_id);
                if ($student === null) {
                    return null;
                }

                return $this->studentSpotlight(
                    $student,
                    round((float) $row->rating_average, 1),
                    (int) $masterCounts->get($student->id, 0),
                    'top_rated',
                );
            })
            ->filter()
            ->values()
            ->take(40)
            ->all();
    }

    /**
     * @return list<array<string, mixed>>
     */
    private function longestStudents(): array
    {
        return StudentProfile::query()
            ->with('academicLevel')
            ->where('status', ProfileStatus::Active->value)
            ->orderBy('created_at')
            ->limit(40)
            ->get()
            ->map(fn (StudentProfile $student) => $this->studentSpotlight($student, null, 0, 'longest'))
            ->all();
    }

    /**
     * @return array<string, mixed>
     */
    private function studentSpotlight(StudentProfile $student, ?float $ratingAverage, int $completedMasterClasses, string $reason): array
    {
        $created = $student->created_at ?? AppClock::now();
        $months = max(1, (int) $created->diffInMonths(AppClock::now()) + 1);

        return [
            'id' => $student->id,
            'full_name' => $student->full_name,
            'student_code' => $student->student_code,
            'level_name' => $student->academicLevel?->name,
            'rating_average' => $ratingAverage,
            'completed_master_classes' => $completedMasterClasses,
            'months_with_us' => $months,
            'reason' => $reason,
        ];
    }

    /**
     * @return list<array<string, mixed>>
     */
    private function topTeachers(?int $year, ?int $month): array
    {
        $rows = SessionBooking::query()
            ->selectRaw("teacher_id,
                sum(case when type = ? and status != ? then 1 else 0 end) as interviews,
                sum(case when type = ? and status != ? then 1 else 0 end) as master_classes", [
                SessionBookingType::IntroductionCall->value,
                SessionBookingStatus::Cancelled->value,
                SessionBookingType::MasterClass->value,
                SessionBookingStatus::Cancelled->value,
            ])
            ->when($year !== null && $month !== null, fn ($query) => $query->whereYear('date', $year)->whereMonth('date', $month))
            ->groupBy('teacher_id')
            ->orderByRaw('(sum(case when type = ? and status != ? then 1 else 0 end) + sum(case when type = ? and status != ? then 1 else 0 end)) desc', [
                SessionBookingType::IntroductionCall->value,
                SessionBookingStatus::Cancelled->value,
                SessionBookingType::MasterClass->value,
                SessionBookingStatus::Cancelled->value,
            ])
            ->limit(40)
            ->get();

        $teachers = TeacherProfile::query()->whereIn('id', $rows->pluck('teacher_id'))->get()->keyBy('id');
        $promoted = $this->promotedCountsByTeacher($rows->pluck('teacher_id')->all());

        return $rows->map(function ($row) use ($teachers, $promoted): ?array {
            $teacher = $teachers->get($row->teacher_id);
            if ($teacher === null) {
                return null;
            }

            return [
                'id' => $teacher->id,
                'full_name' => $teacher->full_name,
                'interviews' => (int) $row->interviews,
                'master_classes' => (int) $row->master_classes,
                'promoted_students' => (int) ($promoted[$teacher->id] ?? 0),
            ];
        })->filter()->values()->all();
    }

    /**
     * @param  list<string>  $teacherIds
     * @return array<string, int>
     */
    private function promotedCountsByTeacher(array $teacherIds): array
    {
        if ($teacherIds === []) {
            return [];
        }

        $studentIdsByTeacher = MasterTeacherAssignment::query()
            ->whereIn('teacher_id', $teacherIds)
            ->get(['teacher_id', 'student_id'])
            ->groupBy('teacher_id')
            ->map(fn ($rows) => $rows->pluck('student_id')->unique()->values());

        $promotedStudentIds = StudentLevelJourney::query()
            ->whereNotNull('ended_at')
            ->whereIn('student_id', $studentIdsByTeacher->flatten()->unique())
            ->pluck('student_id')
            ->unique();

        $counts = [];
        foreach ($studentIdsByTeacher as $teacherId => $studentIds) {
            $counts[$teacherId] = $studentIds->intersect($promotedStudentIds)->count();
        }

        return $counts;
    }

    /**
     * @return array<string, mixed>
     */
    public function promotedStudentsFor(TeacherProfile $teacher): array
    {
        $studentIds = MasterTeacherAssignment::query()
            ->where('teacher_id', $teacher->id)
            ->pluck('student_id')
            ->unique();

        $promotedIds = StudentLevelJourney::query()
            ->whereNotNull('ended_at')
            ->whereIn('student_id', $studentIds)
            ->pluck('student_id')
            ->unique();

        return [
            'count' => $promotedIds->count(),
            'student_ids' => $promotedIds->values()->all(),
        ];
    }
}
