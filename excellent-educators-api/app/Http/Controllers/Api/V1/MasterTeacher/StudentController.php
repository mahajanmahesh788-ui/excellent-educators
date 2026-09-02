<?php

namespace App\Http\Controllers\Api\V1\MasterTeacher;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\StudentResource;
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

        $studentIds = $teacher->activeMasterTeacherAssignments()->pluck('student_id');
        $students = StudentProfile::query()
            ->whereIn('id', $studentIds)
            ->with([
                'user',
                'careerCompassLevel',
                'activeEnrollment.batch.activeTeacherAssignment.teacher',
                'activeMasterTeacherAssignment.teacher',
            ])
            ->when($request->has('rated'), function ($query) use ($request, $year, $month): void {
                $rated = $request->boolean('rated');
                if ($rated) {
                    $query->whereHas('monthlyFeedbacks', fn ($feedback) => $feedback
                        ->where('year', $year)
                        ->where('month', $month));
                } else {
                    $query->whereDoesntHave('monthlyFeedbacks', fn ($feedback) => $feedback
                        ->where('year', $year)
                        ->where('month', $month));
                }
            })
            ->orderBy('full_name')
            ->get();

        $averages = DB::table('monthly_feedback_items')
            ->join('monthly_feedbacks', 'monthly_feedbacks.id', '=', 'monthly_feedback_items.monthly_feedback_id')
            ->whereIn('monthly_feedbacks.student_id', $studentIds)
            ->groupBy('monthly_feedbacks.student_id')
            ->selectRaw('monthly_feedbacks.student_id, avg(monthly_feedback_items.rating) as overall_average')
            ->pluck('overall_average', 'student_id');

        $students->each(function (StudentProfile $student) use ($averages, $year, $month): void {
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
        });

        return ApiResponse::success(
            'Students fetched successfully.',
            StudentResource::collection($students)->resolve(),
        );
    }

    public function show(Request $request, StudentProfile $student): JsonResponse
    {
        $teacher = $request->user()?->teacherProfile;
        $assigned = $teacher && $teacher->activeMasterTeacherAssignments()->where('student_id', $student->id)->exists();
        if (! $assigned) {
            return ApiResponse::error('This action is unauthorized.', 'FORBIDDEN', null, 403);
        }

        ['year' => $year, 'month' => $month] = AppClock::currentYearMonth();

        $student->load([
            'user',
            'careerCompassLevel',
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
