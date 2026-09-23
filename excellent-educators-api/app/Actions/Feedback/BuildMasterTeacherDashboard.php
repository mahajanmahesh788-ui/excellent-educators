<?php

namespace App\Actions\Feedback;

use App\Feedback\StudentsDueForRating;
use App\Models\MonthlyFeedback;
use App\Models\StudentProfile;
use App\Models\TeacherProfile;
use App\Support\AppClock;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class BuildMasterTeacherDashboard
{
    public function __construct(private readonly StudentsDueForRating $studentsDueForRating) {}

    /**
     * @return array<string, mixed>
     */
    public function execute(TeacherProfile $teacher): array
    {
        ['year' => $year, 'month' => $month] = AppClock::currentYearMonth();

        $studentIds = $teacher->rosterStudentIds();
        $assignedStudents = $studentIds->count();
        $dueIds = $this->studentsDueForRating->idsFor($teacher, $year, $month);

        $ratedStudentIds = $studentIds->isEmpty()
            ? collect()
            : MonthlyFeedback::query()
                ->where('master_teacher_id', $teacher->id)
                ->whereIn('student_id', $studentIds)
                ->where('year', $year)
                ->where('month', $month)
                ->pluck('student_id')
                ->unique()
                ->values();

        $ratedThisMonth = $ratedStudentIds->count();
        $notRatedThisMonth = $dueIds->count();

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

        $latestRatings = $studentIds->isEmpty()
            ? collect()
            : MonthlyFeedback::query()
                ->where('master_teacher_id', $teacher->id)
                ->whereIn('student_id', $studentIds)
                ->where('year', $year)
                ->where('month', $month)
                ->orderByDesc('session_date')
                ->get(['id', 'student_id'])
                ->unique('student_id')
                ->keyBy('student_id');

        $pendingStudents = $dueIds->isEmpty()
            ? collect()
            : StudentProfile::query()
                ->whereIn('id', $dueIds)
                ->orderBy('full_name')
                ->get(['id', 'full_name', 'student_code'])
                ->values()
                ->take(8);

        $studentsAssessmentPending = $studentIds->isEmpty()
            ? 0
            : StudentProfile::query()
                ->whereIn('id', $studentIds)
                ->whereDoesntHave('latestAptitudeAssessmentResult')
                ->count();

        $completionRate = $dueIds->isEmpty()
            ? 0
            : round($ratedThisMonth / $dueIds->count(), 2);

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
                ->map(function (StudentProfile $student) use ($latestRatings): array {
                    $feedbackId = $latestRatings->get($student->id)?->id;

                    return [
                        'id' => $student->id,
                        'full_name' => $student->full_name,
                        'student_code' => $student->student_code,
                        'monthly_feedback_id' => $feedbackId,
                        'can_rate' => true,
                        'can_edit_rating' => $feedbackId !== null,
                    ];
                })
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
