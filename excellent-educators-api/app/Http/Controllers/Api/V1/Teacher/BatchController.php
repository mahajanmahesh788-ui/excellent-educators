<?php

namespace App\Http\Controllers\Api\V1\Teacher;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\BatchResource;
use App\Http\Resources\Api\V1\StudentResource;
use App\Models\Batch;
use App\Models\StudentProfile;
use App\Support\ApiResponse;
use App\Support\AppClock;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class BatchController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $teacher = $request->user()?->teacherProfile;
        if ($teacher === null) {
            return ApiResponse::success('Batches fetched successfully.', []);
        }

        $batchIds = $teacher->activeBatchAssignments()->pluck('batch_id');
        $batches = Batch::query()
            ->whereIn('id', $batchIds)
            ->with(['activeTeacherAssignment.teacher'])
            ->withCount('activeEnrollments')
            ->orderBy('name')
            ->get();

        return ApiResponse::success('Batches fetched successfully.', BatchResource::collection($batches)->resolve());
    }

    public function students(Request $request, Batch $batch): JsonResponse
    {
        $teacher = $request->user()?->teacherProfile;
        $assigned = $teacher && $teacher->activeBatchAssignments()->where('batch_id', $batch->id)->exists();
        if (! $assigned) {
            return ApiResponse::error('This action is unauthorized.', 'FORBIDDEN', null, 403);
        }

        $students = $batch->activeEnrollments()
            ->with([
                'student.user',
                'student.activeEnrollment.batch.activeTeacherAssignment.teacher',
                'student.activeMasterTeacherAssignment.teacher',
            ])
            ->get()
            ->pluck('student');

        ['year' => $year, 'month' => $month] = AppClock::currentYearMonth();
        $studentIds = $students->pluck('id');

        $averages = DB::table('monthly_feedback_items')
            ->join('monthly_feedbacks', 'monthly_feedbacks.id', '=', 'monthly_feedback_items.monthly_feedback_id')
            ->whereIn('monthly_feedbacks.student_id', $studentIds)
            ->groupBy('monthly_feedbacks.student_id')
            ->selectRaw('monthly_feedbacks.student_id, avg(monthly_feedback_items.rating) as overall_average')
            ->pluck('overall_average', 'student_id');

        $students->each(function (StudentProfile $student) use ($averages, $year, $month): void {
            $student->loadCount([
                'monthlyFeedbacks as feedback_total_sessions',
                'monthlyFeedbacks as feedback_current_month_sessions' => fn ($query) => $query
                    ->where('year', $year)
                    ->where('month', $month),
            ]);
            $student->feedback_overall_average = $averages[$student->id] ?? null;
        });

        return ApiResponse::success(
            'Batch students fetched successfully.',
            StudentResource::collection($students)->resolve(),
        );
    }
}
