<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Actions\Students\CreateStudent;
use App\Actions\Students\UpdateStudent;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Admin\StoreStudentRequest;
use App\Http\Requests\Api\V1\Admin\UpdateStudentRequest;
use App\Http\Resources\Api\V1\StudentResource;
use App\Models\StudentProfile;
use App\Support\ApiResponse;
use App\Support\AppClock;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class StudentController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $students = StudentProfile::query()
            ->with($this->studentRelations())
            ->withCount($this->feedbackCounts())
            ->when($request->string('search')->toString(), function ($query, string $search): void {
                $digits = preg_replace('/\D+/', '', $search) ?? '';

                $query->where(function ($inner) use ($search, $digits): void {
                    $inner->where('full_name', 'like', "%{$search}%")
                        ->orWhere('student_code', 'like', "%{$search}%")
                        ->orWhere('phone', 'like', "%{$search}%")
                        ->orWhereHas('user', fn ($user) => $user->where('email', 'like', "%{$search}%"));

                    if ($digits !== '') {
                        $inner->orWhere('phone', 'like', "%{$digits}%");
                    }
                });
            })
            ->when($request->filled('career_compass_level_id'), fn ($query) => $query->where('career_compass_level_id', $request->string('career_compass_level_id')))
            ->when($request->filled('status'), fn ($query) => $query->where('status', $request->string('status')))
            ->when($request->has('without_batch'), fn ($query) => $query->whereDoesntHave('activeEnrollment'))
            ->when($request->has('without_master_teacher'), fn ($query) => $query->whereDoesntHave('activeMasterTeacherAssignment'))
            ->when($request->has('assessment_pending'), fn ($query) => $query->whereDoesntHave('latestAptitudeAssessmentResult'))
            ->when($request->has('without_rating_this_month'), function ($query): void {
                ['year' => $year, 'month' => $month] = AppClock::currentYearMonth();
                $dueIds = app(\App\Feedback\StudentsDueForRating::class)->idsThisMonth($year, $month);
                if ($dueIds->isEmpty()) {
                    $query->whereRaw('1 = 0');

                    return;
                }

                $query->whereIn('id', $dueIds)
                    ->whereDoesntHave('monthlyFeedbacks', fn ($feedback) => $feedback
                        ->where('year', $year)
                        ->where('month', $month));
            })
            ->orderBy('full_name')
            ->paginate((int) $request->integer('per_page', 15));

        return ApiResponse::success(
            'Students fetched successfully.',
            StudentResource::collection($students)->resolve(),
            [
                'page' => $students->currentPage(),
                'per_page' => $students->perPage(),
                'total' => $students->total(),
            ],
        );
    }

    public function store(StoreStudentRequest $request, CreateStudent $createStudent): JsonResponse
    {
        $student = $createStudent->execute($request->validated());
        $student->load($this->studentRelations());
        $student->loadCount($this->feedbackCounts());

        return ApiResponse::success('Student created successfully.', StudentResource::make($student)->resolve(), status: 201);
    }

    public function show(StudentProfile $student): JsonResponse
    {
        $student->load($this->studentRelations());
        $student->loadCount($this->feedbackCounts());

        return ApiResponse::success('Student fetched successfully.', StudentResource::make($student)->resolve());
    }

    public function update(UpdateStudentRequest $request, StudentProfile $student, UpdateStudent $updateStudent): JsonResponse
    {
        $student = $updateStudent->execute($student, $request->validated());
        $student->load($this->studentRelations());
        $student->loadCount($this->feedbackCounts());

        return ApiResponse::success('Student updated successfully.', StudentResource::make($student)->resolve());
    }

    /**
     * @return list<string>
     */
    private function studentRelations(): array
    {
        return [
            'user',
            'careerCompassLevel',
            'activeEnrollment.batch.activeTeacherAssignment.teacher',
            'activeMasterTeacherAssignment.teacher',
            'latestAptitudeAssessmentResult.attempt.assessment',
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function feedbackCounts(): array
    {
        ['year' => $year, 'month' => $month] = AppClock::currentYearMonth();

        return [
            'monthlyFeedbacks as feedback_total_sessions',
            'monthlyFeedbacks as feedback_current_month_sessions' => fn ($query) => $query
                ->where('year', $year)
                ->where('month', $month),
        ];
    }
}
