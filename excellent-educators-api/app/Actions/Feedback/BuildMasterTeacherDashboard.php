<?php

namespace App\Actions\Feedback;

use App\Models\MonthlyFeedback;
use App\Models\StudentProfile;
use App\Models\TeacherProfile;
use App\Support\AppClock;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class BuildMasterTeacherDashboard
{
    /**
     * @return array<string, mixed>
     */
    public function execute(TeacherProfile $teacher): array
    {
        ['year' => $year, 'month' => $month] = AppClock::currentYearMonth();

        $studentIds = $teacher->activeMasterTeacherAssignments()->pluck('student_id');
        $assignedStudents = $studentIds->count();

        $ratedThisMonth = $assignedStudents === 0
            ? 0
            : MonthlyFeedback::query()
                ->where('master_teacher_id', $teacher->id)
                ->whereIn('student_id', $studentIds)
                ->where('year', $year)
                ->where('month', $month)
                ->count();

        $notRatedThisMonth = max(0, $assignedStudents - $ratedThisMonth);

        $totalRatings = MonthlyFeedback::query()
            ->where('master_teacher_id', $teacher->id)
            ->when($studentIds->isNotEmpty(), fn ($query) => $query->whereIn('student_id', $studentIds))
            ->count();

        $overallAverage = $studentIds->isEmpty()
            ? null
            : DB::table('monthly_feedback_items')
                ->join('monthly_feedbacks', 'monthly_feedbacks.id', '=', 'monthly_feedback_items.monthly_feedback_id')
                ->where('monthly_feedbacks.master_teacher_id', $teacher->id)
                ->whereIn('monthly_feedbacks.student_id', $studentIds)
                ->avg('monthly_feedback_items.rating');

        $byMonth = $this->ratingsByMonth($teacher->id, $studentIds);

        $pendingStudents = $studentIds->isEmpty()
            ? collect()
            : StudentProfile::query()
                ->whereIn('id', $studentIds)
                ->whereDoesntHave('monthlyFeedbacks', fn ($feedback) => $feedback
                    ->where('master_teacher_id', $teacher->id)
                    ->where('year', $year)
                    ->where('month', $month))
                ->orderBy('full_name')
                ->limit(6)
                ->get(['id', 'full_name', 'student_code']);

        $studentsAssessmentPending = $studentIds->isEmpty()
            ? 0
            : StudentProfile::query()
                ->whereIn('id', $studentIds)
                ->whereDoesntHave('latestAptitudeAssessmentResult')
                ->count();

        $completionRate = $assignedStudents === 0
            ? 0
            : round($ratedThisMonth / $assignedStudents, 2);

        return [
            'current_month' => [
                'year' => $year,
                'month' => $month,
            ],
            'counts' => [
                'assigned_students' => $assignedStudents,
                'rated_this_month' => $ratedThisMonth,
                'not_rated_this_month' => $notRatedThisMonth,
                'total_ratings' => $totalRatings,
                'overall_average' => $overallAverage === null ? null : round((float) $overallAverage, 1),
                'completion_rate' => $completionRate,
                'students_assessment_pending' => $studentsAssessmentPending,
            ],
            'by_month' => $byMonth,
            'pending_students' => $pendingStudents
                ->map(fn (StudentProfile $student): array => [
                    'id' => $student->id,
                    'full_name' => $student->full_name,
                    'student_code' => $student->student_code,
                ])
                ->values()
                ->all(),
        ];
    }

    /**
     * @param  Collection<int, string>  $studentIds
     * @return list<array<string, mixed>>
     */
    private function ratingsByMonth(string $teacherId, Collection $studentIds): array
    {
        if ($studentIds->isEmpty()) {
            return [];
        }

        $rows = DB::table('monthly_feedbacks')
            ->leftJoin('monthly_feedback_items', 'monthly_feedback_items.monthly_feedback_id', '=', 'monthly_feedbacks.id')
            ->where('monthly_feedbacks.master_teacher_id', $teacherId)
            ->whereIn('monthly_feedbacks.student_id', $studentIds)
            ->groupBy('monthly_feedbacks.year', 'monthly_feedbacks.month')
            ->orderBy('monthly_feedbacks.year')
            ->orderBy('monthly_feedbacks.month')
            ->selectRaw('monthly_feedbacks.year as year')
            ->selectRaw('monthly_feedbacks.month as month')
            ->selectRaw('count(distinct monthly_feedbacks.id) as students_rated')
            ->selectRaw('avg(monthly_feedback_items.rating) as average_rating')
            ->get();

        return $rows
            ->map(fn ($row): array => [
                'year' => (int) $row->year,
                'month' => (int) $row->month,
                'students_rated' => (int) $row->students_rated,
                'average_rating' => $row->average_rating === null ? null : round((float) $row->average_rating, 1),
            ])
            ->values()
            ->all();
    }
}
