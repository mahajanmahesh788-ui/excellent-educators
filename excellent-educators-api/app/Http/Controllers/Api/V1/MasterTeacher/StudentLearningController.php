<?php

namespace App\Http\Controllers\Api\V1\MasterTeacher;

use App\Actions\AdminRequests\CreateTeacherAdminRequest;
use App\Enums\AdminRequestType;
use App\Http\Controllers\Api\V1\Concerns\AuthorizesLearningJournal;
use App\Http\Controllers\Api\V1\Concerns\ResolvesTeacherProfile;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Admin\PromoteStudentRequest;
use App\Http\Resources\Api\V1\AdminRequestResource;
use App\Learning\LearningJournalService;
use App\Models\StudentProfile;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class StudentLearningController extends Controller
{
    use AuthorizesLearningJournal;
    use ResolvesTeacherProfile;

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

    /**
     * Master Teachers cannot promote directly — they request admin approval.
     */
    public function promote(
        PromoteStudentRequest $request,
        StudentProfile $student,
        CreateTeacherAdminRequest $createTeacherAdminRequest,
    ): JsonResponse {
        $this->assertCanPromote($request, $student);

        $adminRequest = $createTeacherAdminRequest->execute($request->user(), [
            'request_type' => AdminRequestType::PromoteStudent->value,
            'student_id' => $student->id,
            'level_id' => $request->validated('level_id'),
            'reason' => $request->input('reason'),
        ]);

        $adminRequest->load(['user.teacherProfile', 'student', 'fromLevel', 'targetLevel']);

        return ApiResponse::success(
            'Level upgrade request sent to admin.',
            AdminRequestResource::make($adminRequest)->resolve(),
            status: 201,
        );
    }
}
