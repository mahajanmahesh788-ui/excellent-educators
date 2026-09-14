<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Actions\Students\PromoteStudent;
use App\Http\Controllers\Api\V1\Concerns\AuthorizesLearningJournal;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Admin\PromoteStudentRequest;
use App\Http\Resources\Api\V1\StudentResource;
use App\Learning\LearningJournalService;
use App\Models\AcademicLevel;
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
            $journal->journal($student, $this->staffView($request)),
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
            $journal->weekDetail($student, $journey, $week, $this->staffView($request)),
        );
    }

    public function promote(
        PromoteStudentRequest $request,
        StudentProfile $student,
        PromoteStudent $promoteStudent,
    ): JsonResponse {
        $this->assertCanPromote($request, $student);
        $level = AcademicLevel::query()->findOrFail($request->validated('level_id'));
        $student = $promoteStudent->execute($student, $level, $request->user());
        $student->load([
            'user',
            'academicLevel',
            'activeEnrollment.batch.activeTeacherAssignment.teacher',
            'activeMasterTeacherAssignment.teacher',
        ]);

        return ApiResponse::success('Student promoted successfully.', StudentResource::make($student)->resolve());
    }
}
