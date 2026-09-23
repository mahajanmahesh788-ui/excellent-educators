<?php

namespace App\Http\Controllers\Api\V1\MasterTeacher;

use App\Feedback\StudentsDueForRating;
use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\StudentResource;
use App\Models\MonthlyFeedback;
use App\Models\StudentProfile;
use App\Support\ApiResponse;
use App\Support\AppClock;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class StudentController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $teacher = $request->user()?->teacherProfile;
        if ($teacher === null) {
            return ApiResponse::success('Students fetched successfully.', []);
        }

        ['year' => $year, 'month' => $month] = $this->resolveYearMonth($request);

        $studentIds = $teacher->rosterStudentIds();
        $dueIds = app(StudentsDueForRating::class)->idsFor($teacher, $year, $month);
        $students = StudentProfile::query()
            ->whereIn('id', $studentIds)
            ->with([
                'user',
                'academicLevel.masterTeachers.user',
                'activeEnrollment.batch.level.masterTeachers.user',
                'activeEnrollment.batch.activeTeacherAssignment.teacher',
                'activeMasterTeacherAssignment.teacher',
            ])
            ->when($request->filled('level_id'), function ($query) use ($request): void {
                $levelId = $request->string('level_id')->toString();
                $query->where(function ($inner) use ($levelId): void {
                    $inner->where('level_id', $levelId)
                        ->orWhereHas('activeEnrollment.batch', fn ($batch) => $batch->where('level_id', $levelId));
                });
            })
            ->when($request->filled('batch_id'), function ($query) use ($request): void {
                $query->whereHas('activeEnrollment', fn ($enrollment) => $enrollment
                    ->whereNull('left_at')
                    ->where('batch_id', $request->string('batch_id')));
            })
            ->when($request->has('rated'), function ($query) use ($request, $year, $month, $dueIds): void {
                $rated = $request->boolean('rated');
                if ($rated) {
                    $query->whereHas('monthlyFeedbacks', fn ($feedback) => $feedback
                        ->where('year', $year)
                        ->where('month', $month));

                    return;
                }

                if ($dueIds->isEmpty()) {
                    $query->whereRaw('1 = 0');

                    return;
                }

                $query->whereIn('id', $dueIds);
            })
            ->orderBy('full_name')
            ->get();

        $averages = DB::table('monthly_feedback_items')
            ->join('monthly_feedbacks', 'monthly_feedbacks.id', '=', 'monthly_feedback_items.monthly_feedback_id')
            ->whereIn('monthly_feedbacks.student_id', $studentIds)
            ->groupBy('monthly_feedbacks.student_id')
            ->selectRaw('monthly_feedbacks.student_id, avg(monthly_feedback_items.rating) as overall_average')
            ->pluck('overall_average', 'student_id');

        $feedbackByStudent = $dueIds->isEmpty()
        ? collect()
        : MonthlyFeedback::query()
            ->where('master_teacher_id', $teacher->id)
            ->whereIn('student_id', $dueIds)
            ->where('year', $year)
            ->where('month', $month)
            ->get(['id', 'student_id'])
            ->groupBy('student_id');

        $students->each(function (StudentProfile $student) use ($averages, $year, $month, $dueIds, $feedbackByStudent): void {
            $student->feedback_filter_year = $year;
            $student->feedback_filter_month = $month;
            $student->loadCount([
                'monthlyFeedbacks as feedback_total_sessions',
                'monthlyFeedbacks as feedback_current_month_sessions' => fn ($query) => $query
                    ->where('year', $year)
                    ->where('month', $month),
                'monthlyFeedbacks as feedback_filter_sessions' => fn ($query) => $query
                    ->where('year', $year)
                    ->where('month', $month),
            ]);
            $student->feedback_overall_average = $averages[$student->id] ?? null;
            $due = $dueIds->contains($student->id);
            $ownRatings = $feedbackByStudent->get($student->id);
            $feedbackId = $ownRatings?->first()?->id;
            $student->can_rate_this_month = $due;
            $student->can_edit_rating_this_month = $due && $feedbackId !== null;
            $student->monthly_feedback_id = $feedbackId;
        });

        $levels = $teacher->academicLevels()
            ->with(['batches' => fn ($query) => $query->orderBy('name')])
            ->orderBy('name')
            ->get()
            ->map(fn ($level) => [
                'id' => $level->id,
                'name' => $level->name,
                'batches' => $level->batches->map(fn ($batch) => [
                    'id' => $batch->id,
                    'name' => $batch->name,
                ])->values()->all(),
            ])
            ->values()
            ->all();

        return ApiResponse::success(
            'Students fetched successfully.',
            StudentResource::collection($students)->resolve(),
            ['levels' => $levels],
        );
    }

    public function show(Request $request, StudentProfile $student): JsonResponse
    {
        $teacher = $request->user()?->teacherProfile;
        $assigned = $teacher && $teacher->canAccessStudent($student);
        if (! $assigned) {
            return ApiResponse::error('This action is unauthorized.', 'FORBIDDEN', null, 403);
        }

        ['year' => $year, 'month' => $month] = AppClock::currentYearMonth();

        $student->load([
            'user',
            'academicLevel.masterTeachers.user',
            'activeEnrollment.batch.level.masterTeachers.user',
            'activeEnrollment.batch.activeTeacherAssignment.teacher',
            'activeMasterTeacherAssignment.teacher',
        ])->loadCount([
            'monthlyFeedbacks as feedback_total_sessions',
            'monthlyFeedbacks as feedback_current_month_sessions' => fn ($query) => $query
                ->where('year', $year)
                ->where('month', $month),
        ]);

        $student->feedback_overall_average = DB::table('monthly_feedback_items')
            ->join('monthly_feedbacks', 'monthly_feedbacks.id', '=', 'monthly_feedback_items.monthly_feedback_id')
            ->where('monthly_feedbacks.student_id', $student->id)
            ->avg('monthly_feedback_items.rating');

        $due = app(StudentsDueForRating::class)->idsFor($teacher, $year, $month)->contains($student->id);
        $feedback = MonthlyFeedback::query()
            ->where('student_id', $student->id)
            ->where('master_teacher_id', $teacher->id)
            ->where('year', $year)
            ->where('month', $month)
            ->orderByDesc('session_date')
            ->first();
        $student->can_rate_this_month = $due;
        $student->can_edit_rating_this_month = $feedback !== null;
        $student->monthly_feedback_id = $feedback?->id;

        return ApiResponse::success('Student fetched successfully.', StudentResource::make($student)->resolve());
    }

    /**
     * @return array{year: int, month: int}
     */
    private function resolveYearMonth(Request $request): array
    {
        ['year' => $defaultYear, 'month' => $defaultMonth] = AppClock::currentYearMonth();

        $year = (int) $request->integer('year', $defaultYear);
        $month = (int) $request->integer('month', $defaultMonth);

        return [
            'year' => max(2000, min(2100, $year)),
            'month' => max(1, min(12, $month)),
        ];
    }
}
