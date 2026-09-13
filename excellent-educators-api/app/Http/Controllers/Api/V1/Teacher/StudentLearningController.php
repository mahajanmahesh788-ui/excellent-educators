<?php

namespace App\Http\Controllers\Api\V1\Teacher;

use App\Http\Controllers\Api\V1\Concerns\AuthorizesLearningJournal;
use App\Http\Controllers\Controller;
use App\Learning\LearningJournalService;
use App\Models\StudentProfile;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class StudentLearningController extends Controller
{
    use AuthorizesLearningJournal;

    public function journal(Request $request, StudentProfile $student, LearningJournalService $journal): JsonResponse
    {
        $this->assertCanViewJournal($request, $student);
        $student->loadMissing('academicLevel');

        return ApiResponse::success(
            'Learning journal fetched successfully.',
            $journal->journal($student, true),
        );
    }

    public function week(
        Request $request,
        StudentProfile $student,
        string $journey,
        int $week,
        LearningJournalService $journal,
    ): JsonResponse {
        $this->assertCanViewJournal($request, $student);
        $student->loadMissing('academicLevel');

        return ApiResponse::success(
            'Weekly learning fetched successfully.',
            $journal->weekDetail($student, $journey, $week, true),
        );
    }
}
