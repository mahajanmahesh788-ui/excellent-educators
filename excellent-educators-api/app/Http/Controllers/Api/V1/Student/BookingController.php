<?php

namespace App\Http\Controllers\Api\V1\Student;

use App\Actions\Scheduling\CreateSessionBooking;
use App\Actions\Scheduling\RescheduleSessionBooking;
use App\Attendance\AttendanceService;
use App\Enums\AttendanceIssueType;
use App\Enums\JoinActorType;
use App\Enums\SessionBookingStatus;
use App\Http\Controllers\Api\V1\Concerns\ResolvesTeacherProfile;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Attendance\StoreAttendanceReportRequest;
use App\Http\Requests\Api\V1\Scheduling\StoreBookingRequest;
use App\Http\Resources\Api\V1\TeacherResource;
use App\Models\SessionBooking;
use App\Models\TeacherProfile;
use App\Scheduling\AvailabilityCalculator;
use App\Scheduling\BookingEligibility;
use App\Support\ApiResponse;
use App\Support\ErrorCode;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BookingController extends Controller
{
    use ResolvesTeacherProfile;

    public function __construct(
        private readonly AvailabilityCalculator $availability,
        private readonly BookingEligibility $eligibility,
    ) {}

    public function eligibility(Request $request): JsonResponse
    {
        return ApiResponse::success(
            'Eligibility fetched successfully.',
            $this->eligibility->forStudent($this->studentFrom($request)),
        );
    }

    public function teachers(Request $request): JsonResponse
    {
        $request->attributes->set('include_public_mentor_stats_baseline', true);

        $teachers = $this->eligibility->eligibleTeachers($this->studentFrom($request)->loadMissing([
            'academicLevel.masterTeachers.user',
            'activeEnrollment.batch.level.masterTeachers.user',
        ]));

        return ApiResponse::success(
            'Teachers fetched successfully.',
            TeacherResource::collection($teachers)->resolve(),
        );
    }

    public function showTeacher(Request $request, TeacherProfile $teacher): JsonResponse
    {
        $request->attributes->set('include_public_mentor_stats_baseline', true);

        $student = $this->studentFrom($request)->loadMissing([
            'academicLevel.masterTeachers.user',
            'activeEnrollment.batch.level.masterTeachers.user',
        ]);
        if (! $this->eligibility->teacherIsEligible($student, $teacher)) {
            return ApiResponse::error('This teacher is not assigned to your level.', ErrorCode::TEACHER_NOT_ELIGIBLE, null, 422);
        }

        $teacher->load(['user.roles', 'academicLevels'])
            ->loadCount(['activeBatchAssignments', 'activeMasterTeacherAssignments']);

        return ApiResponse::success(
            'Mentor profile fetched successfully.',
            TeacherResource::make($teacher)->resolve(),
        );
    }

    public function availability(Request $request): JsonResponse
    {
        $request->validate([
            'teacher_id' => ['required', 'string'],
            'date' => ['required', 'date'],
        ]);
        $student = $this->studentFrom($request);
        $teacher = TeacherProfile::query()->findOrFail($request->string('teacher_id'));
        if (! $this->eligibility->teacherIsEligible($student, $teacher)) {
            return ApiResponse::error('This teacher is not assigned to your level.', ErrorCode::TEACHER_NOT_ELIGIBLE, null, 422);
        }

        $date = $request->string('date')->toString();
        $day = $this->availability->day(
            $teacher,
            $date,
            bookableOnly: true,
            includeBookingPayloads: false,
        );
        unset($day['breaks'], $day['leaves'], $day['bookings'], $day['availability_source'], $day['availability_ranges']);
        $day['slots'] = array_values(array_map(static function (array $slot): array {
            return [
                'start' => $slot['start'],
                'end' => $slot['end'],
                'status' => 'available',
            ];
        }, $day['slots'] ?? []));

        return ApiResponse::success(
            'Availability fetched successfully.',
            $day,
        );
    }

    public function index(Request $request): JsonResponse
    {
        $student = $this->studentFrom($request);
        $bookings = SessionBooking::query()
            ->with([
                'teacher',
                'student.currentLevelJourney',
                'student.levelJourneys',
                'student.academicLevel',
                'student.activeEnrollment.batch.level',
            ])
            ->where('student_id', $student->id)
            ->where('status', '!=', SessionBookingStatus::Cancelled->value)
            ->orderByDesc('starts_at')
            ->limit(200)
            ->get();

        return ApiResponse::success(
            'Bookings fetched successfully.',
            $this->availability->bookingPayloads($bookings, 'student')->all(),
        );
    }

    public function store(StoreBookingRequest $request, CreateSessionBooking $action): JsonResponse
    {
        $booking = $action->execute($this->studentFrom($request), $request->validated());
        $booking->load(['teacher', 'student']);

        return ApiResponse::success('Booking confirmed.', $this->availability->bookingPayload($booking, 'student'), status: 201);
    }

    public function show(Request $request, SessionBooking $booking): JsonResponse
    {
        $student = $this->studentFrom($request);
        if ($booking->student_id !== $student->id) {
            return ApiResponse::error('Booking not found.', ErrorCode::NOT_FOUND, null, 404);
        }
        $booking->load(['teacher', 'student']);

        return ApiResponse::success('Booking fetched successfully.', $this->availability->bookingPayload($booking, 'student'));
    }

    public function reschedule(StoreBookingRequest $request, SessionBooking $booking, RescheduleSessionBooking $action): JsonResponse
    {
        $student = $this->studentFrom($request);
        if ($booking->student_id !== $student->id) {
            return ApiResponse::error('Booking not found.', ErrorCode::NOT_FOUND, null, 404);
        }
        $updated = $action->execute($booking, $request->validated());

        return ApiResponse::success('Booking rescheduled.', $this->availability->bookingPayload($updated, 'student'));
    }

    public function join(Request $request, SessionBooking $booking, AttendanceService $attendance): JsonResponse
    {
        $student = $this->studentFrom($request);
        if ($booking->student_id !== $student->id) {
            return ApiResponse::error('Booking not found.', ErrorCode::NOT_FOUND, null, 404);
        }
        $attendance->recordJoin($booking, JoinActorType::Student, $student->id);
        $booking->load(['teacher', 'student']);

        return ApiResponse::success('Join recorded. This records an attempt to join, not time spent in the meeting.', $this->availability->bookingPayload($booking, 'student'));
    }

    public function reportTeacher(StoreAttendanceReportRequest $request, SessionBooking $booking, AttendanceService $attendance): JsonResponse
    {
        $student = $this->studentFrom($request);
        if ($booking->student_id !== $student->id) {
            return ApiResponse::error('Booking not found.', ErrorCode::NOT_FOUND, null, 404);
        }

        $issueType = match ($request->string('issue_type')->toString()) {
            AttendanceIssueType::StudentDidNotJoin->value => AttendanceIssueType::StudentDidNotJoin,
            default => AttendanceIssueType::TeacherDidNotJoin,
        };

        $attendance->report(
            $booking,
            $request->user(),
            $issueType,
            $request->string('message')->toString(),
        );
        $booking->load(['teacher', 'student']);

        return ApiResponse::success('Report sent to Admin.', $this->availability->bookingPayload($booking, 'student'), status: 201);
    }
}
