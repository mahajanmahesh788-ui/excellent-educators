<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Actions\Scheduling\CancelTeacherLeave;
use App\Actions\Scheduling\CreateSessionBooking;
use App\Actions\Scheduling\CreateTeacherLeave;
use App\Actions\Scheduling\RescheduleSessionBooking;
use App\Actions\Scheduling\UpsertTeacherBreaks;
use App\Enums\SessionBookingStatus;
use App\Enums\TeacherLeaveStatus;
use App\Exceptions\ApiException;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Scheduling\StoreBookingRequest;
use App\Http\Requests\Api\V1\Scheduling\StoreLeaveRequest;
use App\Http\Requests\Api\V1\Scheduling\StoreTeacherAvailabilityOverrideRequest;
use App\Http\Requests\Api\V1\Scheduling\UpdateTeacherAvailabilityRequest;
use App\Http\Requests\Api\V1\Scheduling\UpsertBreaksRequest;
use App\Http\Resources\Api\V1\TeacherResource;
use App\Models\SessionBooking;
use App\Models\StudentProfile;
use App\Models\TeacherAvailabilityOverride;
use App\Models\TeacherLeave;
use App\Models\TeacherProfile;
use App\Scheduling\AvailabilityCalculator;
use App\Scheduling\LeaveRequestAssembler;
use App\Scheduling\MasterClassBalance;
use App\Scheduling\TeacherAvailability;
use App\Support\ApiResponse;
use App\Support\AppClock;
use App\Support\ErrorCode;
use App\Support\StudentActivity;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ScheduleController extends Controller
{
    public function __construct(
        private readonly AvailabilityCalculator $availability,
        private readonly TeacherAvailability $teacherAvailability,
    ) {}

    public function teachers(): JsonResponse
    {
        $teachers = TeacherProfile::query()->with('user.roles')->active()->orderBy('full_name')->get();

        return ApiResponse::success('Teachers fetched successfully.', TeacherResource::collection($teachers)->resolve());
    }

    public function day(Request $request): JsonResponse
    {
        $teacher = $this->teacher($request);
        $date = $request->string('date')->toString() ?: AppClock::todayString();

        return ApiResponse::success('Schedule fetched successfully.', $this->availability->day($teacher, $date));
    }

    public function week(Request $request): JsonResponse
    {
        $teacher = $this->teacher($request);
        $start = $request->string('start')->toString() ?: AppClock::todayString();

        return ApiResponse::success('Week schedule fetched successfully.', [
            'days' => $this->availability->week($teacher, $start),
        ]);
    }

    public function month(Request $request): JsonResponse
    {
        $teacher = $this->teacher($request);
        $now = AppClock::currentYearMonth();

        return ApiResponse::success(
            'Month schedule fetched successfully.',
            $this->availability->month(
                $teacher,
                (int) $request->integer('year', $now['year']),
                (int) $request->integer('month', $now['month']),
            ),
        );
    }

    public function upsertBreaks(UpsertBreaksRequest $request, TeacherProfile $teacher, UpsertTeacherBreaks $action): JsonResponse
    {
        $breaks = $action->execute($teacher, $request->validated());

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
        $items = $assembler->listGrouped(
            $request->filled('teacher_id') ? $request->string('teacher_id')->toString() : null,
            $request->filled('from') ? $request->string('from')->toString() : null,
            $request->filled('to') ? $request->string('to')->toString() : null,
        );

        return ApiResponse::success('Leaves fetched successfully.', $items);
    }

    public function storeLeave(StoreLeaveRequest $request, TeacherProfile $teacher, CreateTeacherLeave $action, LeaveRequestAssembler $assembler): JsonResponse
    {
        $leaves = $action->execute($teacher, $request->validated(), $request->user());
        $group = $assembler->serializeGroup($leaves);

        return ApiResponse::success('Leave request submitted successfully.', $group, status: 201);
    }

    public function destroyLeave(TeacherLeave $leave, CancelTeacherLeave $cancel): JsonResponse
    {
        if ($leave->dateHasPassed()) {
            return ApiResponse::error('Past leave cannot be removed.', ErrorCode::LEAVE_DATE_PASSED, null, 422);
        }

        $status = $leave->status ?? TeacherLeaveStatus::Approved;
        if ($status->isOpen()) {
            $payload = $cancel->execute((string) $leave->request_group_id, request()->user());

            return ApiResponse::success('Leave cancelled successfully.', $payload);
        }

        if ($status !== TeacherLeaveStatus::Approved) {
            return ApiResponse::error('This leave cannot be removed.', ErrorCode::LEAVE_NOT_APPROVABLE, null, 422);
        }

        TeacherLeave::query()
            ->where('request_group_id', $leave->request_group_id)
            ->delete();

        return ApiResponse::success('Leave removed successfully.');
    }

    public function availability(TeacherProfile $teacher): JsonResponse
    {
        return ApiResponse::success('Teacher availability fetched successfully.', $this->teacherAvailability->configFor($teacher));
    }

    public function updateAvailability(UpdateTeacherAvailabilityRequest $request, TeacherProfile $teacher): JsonResponse
    {
        $data = $this->teacherAvailability->replaceWeekly($teacher, $request->validated());

        return ApiResponse::success('Teacher availability saved. Existing bookings were not cancelled.', $data);
    }

    public function storeAvailabilityOverride(StoreTeacherAvailabilityOverrideRequest $request, TeacherProfile $teacher): JsonResponse
    {
        $data = $this->teacherAvailability->upsertOverride($teacher, $request->validated());

        return ApiResponse::success('Special date availability saved. Existing bookings were not cancelled.', $data, status: 201);
    }

    public function destroyAvailabilityOverride(TeacherProfile $teacher, TeacherAvailabilityOverride $override): JsonResponse
    {
        if ($override->teacher_id !== $teacher->id) {
            return ApiResponse::error('Special date not found.', ErrorCode::NOT_FOUND, null, 404);
        }

        return ApiResponse::success(
            'Special date removed.',
            $this->teacherAvailability->deleteOverride($teacher, $override->id),
        );
    }

    public function bookings(Request $request): JsonResponse
    {
        $bookings = SessionBooking::query()
            ->with(['teacher', 'student'])
            ->when($request->filled('teacher_id'), fn ($q) => $q->where('teacher_id', $request->string('teacher_id')))
            ->when($request->filled('student_id'), fn ($q) => $q->where('student_id', $request->string('student_id')))
            ->when($request->filled('date'), fn ($q) => $q->whereDate('date', $request->string('date')))
            ->where('status', '!=', SessionBookingStatus::Cancelled->value)
            ->orderByDesc('starts_at')
            ->limit(200)
            ->get()
            ->map(fn (SessionBooking $booking) => $this->availability->bookingPayload($booking));

        return ApiResponse::success('Bookings fetched successfully.', $bookings);
    }

    public function storeBooking(StoreBookingRequest $request, CreateSessionBooking $action): JsonResponse
    {
        $student = StudentProfile::query()->findOrFail($request->string('student_id'));
        $booking = $action->execute($student, $request->validated(), skipEligibility: true);
        $booking->load(['teacher', 'student']);

        return ApiResponse::success('Booking created.', $this->availability->bookingPayload($booking), status: 201);
    }

    public function updateBooking(StoreBookingRequest $request, SessionBooking $booking, RescheduleSessionBooking $action): JsonResponse
    {
        $updated = $action->execute($booking, $request->validated(), adminOverride: true);

        return ApiResponse::success('Booking updated.', $this->availability->bookingPayload($updated));
    }

    public function destroyBooking(SessionBooking $booking): JsonResponse
    {
        $wasScheduled = $booking->status === SessionBookingStatus::Scheduled;
        $booking->update(['status' => SessionBookingStatus::Cancelled->value]);
        $booking->load('student');
        if ($wasScheduled && ($booking->type?->value ?? $booking->type) === 'master_class' && $booking->student) {
            app(MasterClassBalance::class)->restore($booking->student);
            $remaining = app(MasterClassBalance::class)->remaining($booking->student);
            StudentActivity::record(
                $booking->student,
                'master_class_cancelled',
                "Master Class booking was cancelled. Remaining this month: {$remaining}",
                related: $booking,
                meta: ['remaining' => $remaining],
            );
        }

        return ApiResponse::success('Booking cancelled.');
    }

    public function completeBooking(SessionBooking $booking): JsonResponse
    {
        $booking->update(['status' => SessionBookingStatus::Completed->value]);

        return ApiResponse::success(
            'Booking marked complete.',
            $this->availability->bookingPayload($booking->fresh(['student', 'teacher'])),
        );
    }

    private function teacher(Request $request): TeacherProfile
    {
        $id = $request->string('teacher_id')->toString();
        if ($id === '') {
            throw new ApiException(ErrorCode::VALIDATION_ERROR, 'teacher_id is required.', 422);
        }

        return TeacherProfile::query()->findOrFail($id);
    }
}
