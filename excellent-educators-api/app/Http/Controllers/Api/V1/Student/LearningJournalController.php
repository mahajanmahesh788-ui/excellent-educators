<?php

namespace App\Http\Controllers\Api\V1\Student;

use App\Http\Controllers\Api\V1\Concerns\ResolvesTeacherProfile;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Learning\SubmitWeeklyAssignmentRequest;
use App\Learning\LearningJournalService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LearningJournalController extends Controller
{
    use ResolvesTeacherProfile;

    public function dashboard(Request $request, LearningJournalService $journal): JsonResponse
    {
        $student = $this->studentFrom($request);

        return ApiResponse::success(
            'Learning dashboard fetched successfully.',
            $journal->dashboard($student, false),
        );
    }

    public function index(Request $request, LearningJournalService $journal): JsonResponse
    {
        $student = $this->studentFrom($request);

        return ApiResponse::success(
            'Learning journal fetched successfully.',
            $journal->journal($student, false),
        );
    }

    public function show(Request $request, string $journey, int $week, LearningJournalService $journal): JsonResponse
    {
        $student = $this->studentFrom($request);

        return ApiResponse::success(
            'Weekly learning fetched successfully.',
            $journal->weekDetail($student, $journey, $week, false),
        );
    }

    public function submit(
        SubmitWeeklyAssignmentRequest $request,
        string $journey,
        int $week,
        LearningJournalService $journal,
    ): JsonResponse {
        $student = $this->studentFrom($request);
        $journal->submit($student, $journey, $week, $request->validated('answers'));

        return ApiResponse::success(
            'Assignment submitted successfully.',
            $journal->weekDetail($student, $journey, $week, false),
            status: 201,
        );
    }
}
