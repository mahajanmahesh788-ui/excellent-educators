<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Attendance\AttendanceService;
use App\Enums\AttendanceDecision;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Attendance\ResolveAttendanceIssueRequest;
use App\Models\AttendanceIssue;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AttendanceController extends Controller
{
    public function __construct(private readonly AttendanceService $attendance) {}

    public function index(Request $request): JsonResponse
    {
        $this->authorize('viewAny', AttendanceIssue::class);
        $status = $request->string('status')->toString();
        $query = AttendanceIssue::query()
            ->with([
                'booking.student.academicLevel',
                'booking.student.activeEnrollment.batch.level',
                'booking.teacher',
                'reporter',
            ])
            ->orderByDesc('created_at');
        if (in_array($status, ['pending', 'resolved'], true)) {
            $query->where('verification_status', $status);
        }

        $items = $query->get()->map(fn (AttendanceIssue $issue) => $this->attendance->issueDetail($issue));

        return ApiResponse::success('Class conflicts fetched.', $items);
    }

    public function show(AttendanceIssue $issue): JsonResponse
    {
        $this->authorize('view', $issue);

        return ApiResponse::success('Attendance report fetched.', $this->attendance->issueDetail($issue));
    }

    public function resolve(ResolveAttendanceIssueRequest $request, AttendanceIssue $issue): JsonResponse
    {
        $this->authorize('resolve', $issue);
        $updated = $this->attendance->resolve(
            $issue,
            $request->user(),
            AttendanceDecision::from($request->string('decision')->toString()),
            $request->input('notes'),
        );

        return ApiResponse::success('Attendance report resolved.', $this->attendance->issueDetail($updated));
    }
}
