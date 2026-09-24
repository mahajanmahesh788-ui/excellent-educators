<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Actions\Scheduling\ApproveTeacherLeave;
use App\Actions\Scheduling\AssignLeaveReplacement;
use App\Actions\Scheduling\CancelTeacherLeave;
use App\Actions\Scheduling\RejectTeacherLeave;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Scheduling\AssignLeaveReplacementRequest;
use App\Http\Requests\Api\V1\Scheduling\RejectLeaveRequest;
use App\Models\SessionBooking;
use App\Scheduling\FindReplacementTeachersForBooking;
use App\Scheduling\LeaveRequestAssembler;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;

class LeaveRequestController extends Controller
{
    public function show(string $groupId, LeaveRequestAssembler $assembler): JsonResponse
    {
        $leaves = $assembler->leavesForGroup($groupId);
        if ($leaves->isEmpty()) {
            return ApiResponse::error('Leave request not found.', 'NOT_FOUND', null, 404);
        }

        return ApiResponse::success(
            'Leave request fetched successfully.',
            $assembler->serializeGroup($leaves, includeReplacementsAvailability: true),
        );
    }

    public function replacements(
        string $groupId,
        SessionBooking $booking,
        LeaveRequestAssembler $assembler,
        FindReplacementTeachersForBooking $findReplacements,
    ): JsonResponse {
        $leaves = $assembler->leavesForGroup($groupId);
        if ($leaves->isEmpty()) {
            return ApiResponse::error('Leave request not found.', 'NOT_FOUND', null, 404);
        }

        $teachers = $findReplacements->execute($booking, $leaves->first()->teacher_id);

        return ApiResponse::success('Replacement teachers fetched successfully.', [
            'booking_id' => $booking->id,
            'teachers' => $teachers->map(fn ($teacher) => [
                'id' => $teacher->id,
                'full_name' => $teacher->full_name,
                'photo_url' => $teacher->photo_url,
            ])->values()->all(),
        ]);
    }

    public function assignReplacement(
        AssignLeaveReplacementRequest $request,
        string $groupId,
        string $bookingId,
        AssignLeaveReplacement $action,
    ): JsonResponse {
        $payload = $action->execute(
            $groupId,
            $bookingId,
            $request->validated('replacement_teacher_id'),
            $request->user(),
        );

        return ApiResponse::success('Replacement assignment saved.', $payload);
    }

    public function approve(string $groupId, ApproveTeacherLeave $action): JsonResponse
    {
        $payload = $action->execute($groupId, request()->user());

        return ApiResponse::success('Leave approved successfully.', $payload);
    }

    public function reject(
        RejectLeaveRequest $request,
        string $groupId,
        RejectTeacherLeave $action,
    ): JsonResponse {
        $payload = $action->execute(
            $groupId,
            $request->user(),
            $request->validated('reason'),
        );

        return ApiResponse::success('Leave rejected successfully.', $payload);
    }

    public function cancel(string $groupId, CancelTeacherLeave $action): JsonResponse
    {
        $payload = $action->execute($groupId, request()->user());

        return ApiResponse::success('Leave cancelled successfully.', $payload);
    }
}
