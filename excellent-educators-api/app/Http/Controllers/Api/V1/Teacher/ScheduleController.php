<?php

namespace App\Http\Controllers\Api\V1\Teacher;

use App\Actions\Scheduling\CancelTeacherLeave;
use App\Actions\Scheduling\CreateTeacherLeave;
use App\Actions\Scheduling\UpsertTeacherBreaks;
use App\Attendance\AttendanceService;
use App\Enums\AttendanceIssueType;
use App\Enums\JoinActorType;
use App\Enums\SessionBookingStatus;
use App\Http\Requests\Api\V1\Attendance\StoreAttendanceReportRequest;
use App\Http\Controllers\Api\V1\Concerns\ResolvesTeacherProfile;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Scheduling\StoreLeaveRequest;
use App\Http\Requests\Api\V1\Scheduling\UpsertBreaksRequest;
use App\Models\SessionBooking;
use App\Models\TeacherLeave;
use App\Scheduling\AvailabilityCalculator;
use App\Scheduling\LeaveRequestAssembler;
use App\Support\ApiResponse;
use App\Support\AppClock;
use App\Support\ErrorCode;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ScheduleController extends Controller
{
    use ResolvesTeacherProfile;

    public function __construct(private readonly AvailabilityCalculator $availability) {}

    public function day(Request $request): JsonResponse
    {
        $teacher = $this->teacherFrom($request);
        $date = $request->string('date')->toString() ?: AppClock::todayString();

        return ApiResponse::success('Schedule fetched successfully.', $this->availability->day($teacher, $date));
    }

    public function week(Request $request): JsonResponse
    {
        $teacher = $this->teacherFrom($request);
        $start = $request->string('start')->toString() ?: AppClock::todayString();

        return ApiResponse::success('Week schedule fetched successfully.', [
            'days' => $this->availability->week($teacher, $start),
        ]);
    }

    public function month(Request $request): JsonResponse
    {
        $teacher = $this->teacherFrom($request);
        $now = AppClock::currentYearMonth();
        $year = (int) $request->integer('year', $now['year']);
        $month = (int) $request->integer('month', $now['month']);

        return ApiResponse::success('Month schedule fetched successfully.', $this->availability->month($teacher, $year, $month));
    }

    public function bookings(Request $request): JsonResponse
    {
        $teacher = $this->teacherFrom($request);
        $bookings = SessionBooking::query()
            ->with(['student', 'teacher', 'reassignedFromTeacher'])
            ->where('teacher_id', $teacher->id)
            ->where('status', '!=', SessionBookingStatus::Cancelled->value)
            ->orderByDesc('starts_at')
            ->limit(500)
            ->get()
            ->map(fn (SessionBooking $booking) => $this->availability->bookingPayload($booking, 'teacher'))
            ->values()
            ->all();

        return ApiResponse::success('Bookings fetched successfully.', $bookings);
    }

    public function breaks(Request $request): JsonResponse
    {
        $teacher = $this->teacherFrom($request);
        $teacher->load('breaks');

        return ApiResponse::success('Breaks fetched successfully.', $this->availability->day($teacher, AppClock::todayString())['breaks']);
    }

    public function upsertBreaks(UpsertBreaksRequest $request, UpsertTeacherBreaks $action): JsonResponse
    {
        $breaks = $action->execute($this->teacherFrom($request), $request->validated());

        return ApiResponse::success('Breaks saved successfully.', [
            'items' => $breaks->map(fn ($break) => [
                'id' => $break->id,
                'type' => $break->type?->value ?? $break->type,
                'start_time' => substr((string) $break->start_time, 0, 5),
                'end_time' => substr((string) $break->end_time, 0, 5),
            ])->all(),
        ]);
    }

    public function leaves(Request $request, LeaveRequestAssembler $assembler): JsonResponse
    {
        $teacher = $this->teacherFrom($request);
        $items = $assembler->listGrouped(
            $teacher->id,
            $request->filled('from') ? $request->string('from')->toString() : null,
            $request->filled('to') ? $request->string('to')->toString() : null,
        );

        return ApiResponse::success('Leaves fetched successfully.', $items);
    }

    public function storeLeave(StoreLeaveRequest $request, CreateTeacherLeave $action, LeaveRequestAssembler $assembler): JsonResponse
    {
        $leaves = $action->execute($this->teacherFrom($request), $request->validated(), $request->user());

        return ApiResponse::success(
            'Leave request submitted successfully.',
            $assembler->serializeGroup($leaves),
            status: 201,
        );
    }

    public function destroyLeave(Request $request, TeacherLeave $leave, CancelTeacherLeave $cancel): JsonResponse
    {
        $teacher = $this->teacherFrom($request);
        if ($leave->teacher_id !== $teacher->id) {
            return ApiResponse::error('Leave not found.', ErrorCode::NOT_FOUND, null, 404);
        }

        $payload = $cancel->execute((string) $leave->request_group_id, $request->user(), $teacher->id);

        return ApiResponse::success('Leave cancelled successfully.', $payload);
    }

    public function completeBooking(Request $request, SessionBooking $booking): JsonResponse
    {
        $teacher = $this->teacherFrom($request);
        if ($booking->teacher_id !== $teacher->id) {
            return ApiResponse::error('Booking not found.', ErrorCode::NOT_FOUND, null, 404);
        }
        $booking->update(['status' => SessionBookingStatus::Completed->value]);

        return ApiResponse::success(
            'Booking marked complete.',
            $this->availability->bookingPayload($booking->fresh(['student', 'teacher']), 'teacher'),
        );
    }

    public function joinBooking(Request $request, SessionBooking $booking, AttendanceService $attendance): JsonResponse
    {
        $teacher = $this->teacherFrom($request);
        if ($booking->teacher_id !== $teacher->id) {
            return ApiResponse::error('Booking not found.', ErrorCode::NOT_FOUND, null, 404);
        }
        $attendance->recordJoin($booking, JoinActorType::Teacher, $teacher->id);

        return ApiResponse::success(
            'Join recorded for this Meet. One click can cover back-to-back classes on the same day.',
            $this->availability->bookingPayload($booking->fresh(['student', 'teacher']), 'teacher'),
        );
    }

    public function reportStudent(StoreAttendanceReportRequest $request, SessionBooking $booking, AttendanceService $attendance): JsonResponse
    {
        $teacher = $this->teacherFrom($request);
        if ($booking->teacher_id !== $teacher->id) {
            return ApiResponse::error('Booking not found.', ErrorCode::NOT_FOUND, null, 404);
        }
        $attendance->report(
            $booking,
            $request->user(),
            AttendanceIssueType::StudentDidNotJoin,
            $request->string('message')->toString(),
        );

        return ApiResponse::success(
            'Report sent to Admin.',
            $this->availability->bookingPayload($booking->fresh(['student', 'teacher']), 'teacher'),
            status: 201,
        );
    }

    public function whatsappStudent(Request $request, SessionBooking $booking, AttendanceService $attendance): JsonResponse
    {
        $teacher = $this->teacherFrom($request);
        if ($booking->teacher_id !== $teacher->id) {
            return ApiResponse::error('Booking not found.', ErrorCode::NOT_FOUND, null, 404);
        }

        return ApiResponse::success(
            'WhatsApp reminder ready.',
            $attendance->teacherWhatsAppReminder($booking),
        );
    }
}
