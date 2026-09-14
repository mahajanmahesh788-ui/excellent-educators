<?php

namespace App\Http\Controllers\Api\V1\Teacher;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\StudentResource;
use App\Models\MonthlyFeedback;
use App\Models\StudentProfile;
use App\Support\ApiResponse;
use App\Support\AppClock;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class StudentController extends Controller
{
    public function show(StudentProfile $student): JsonResponse
    {
        $this->authorize('viewAnyForStudent', [MonthlyFeedback::class, $student]);

        ['year' => $year, 'month' => $month] = AppClock::currentYearMonth();

        $student->load([
            'user',
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
}
