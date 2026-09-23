<?php

namespace App\Actions\Scheduling;

use App\Actions\Notifications\NotifyAdminsOfStudentBookingFailure;
use App\Attendance\AttendanceService;
use App\Enums\SessionBookingStatus;
use App\Enums\SessionBookingType;
use App\Exceptions\ApiException;
use App\Meetings\TeacherDailyMeetingService;
use App\Models\SessionBooking;
use App\Models\StudentProfile;
use App\Models\TeacherProfile;
use App\Scheduling\AvailabilityCalculator;
use App\Scheduling\BookingEligibility;
use App\Scheduling\MasterClassBalance;
use App\Scheduling\SlotGrid;
use App\Support\AppClock;
use App\Support\ErrorCode;
use App\Support\StudentActivity;
use Illuminate\Support\Facades\DB;
use Throwable;

class CreateSessionBooking
{
    public function __construct(
        private readonly AvailabilityCalculator $availability,
        private readonly BookingEligibility $eligibility,
        private readonly TeacherDailyMeetingService $meetings,
        private readonly AttendanceService $attendance,
        private readonly MasterClassBalance $masterClassBalance,
        private readonly NotifyAdminsOfStudentBookingFailure $notifyAdmins,
    ) {}

    /**
     * @param  array<string, mixed>  $payload
     */
    public function execute(StudentProfile $student, array $payload, bool $skipEligibility = false): SessionBooking
    {
        $teacher = TeacherProfile::query()->findOrFail($payload['teacher_id']);
        if (! isset($payload['type'])) {
            throw new ApiException(ErrorCode::VALIDATION_ERROR, 'Booking type is required.', 422);
        }
        $type = SessionBookingType::from((string) $payload['type']);
        $date = (string) $payload['date'];
        $start = (string) $payload['start'];

        try {
            $this->assertSlot($start, $date);

            $consumeRebooking = false;
            if (! $skipEligibility) {
                $consumeRebooking = $this->assertEligibility($student, $teacher, $type);
            }

            return DB::transaction(function () use ($student, $teacher, $type, $date, $start, $consumeRebooking): SessionBooking {
                SessionBooking::query()
                    ->where('teacher_id', $teacher->id)
                    ->whereDate('date', $date)
                    ->lockForUpdate()
                    ->get();

                if (! $this->availability->isSlotAvailable($teacher, $date, $start)) {
                    throw new ApiException(ErrorCode::SLOT_UNAVAILABLE, 'This time slot is no longer available.', 409);
                }

                $startsAt = SlotGrid::atDate($date, $start);
                $endsAt = $startsAt->copy()->addMinutes(SlotGrid::slotMinutes());

                $overlap = SessionBooking::query()
                    ->where('teacher_id', $teacher->id)
                    ->where('status', '!=', SessionBookingStatus::Cancelled->value)
                    ->where('starts_at', '<', $endsAt)
                    ->where('ends_at', '>', $startsAt)
                    ->exists();

                if ($overlap) {
                    throw new ApiException(ErrorCode::BOOKING_OVERLAP, 'This teacher already has a booking in that time.', 409);
                }

                $this->meetings->getOrCreate($teacher, $date);

                $booking = SessionBooking::query()->create([
                    'student_id' => $student->id,
                    'teacher_id' => $teacher->id,
                    'type' => $type->value,
                    'date' => $date,
                    'starts_at' => $startsAt,
                    'ends_at' => $endsAt,
                    'status' => SessionBookingStatus::Scheduled->value,
                ]);

                if ($consumeRebooking) {
                    $this->attendance->consumeRebooking($student->id, $booking);
                }

                if ($type === SessionBookingType::MasterClass) {
                    $this->masterClassBalance->spend($student);
                    $remaining = $this->masterClassBalance->remaining($student);
                    StudentActivity::record(
                        $student,
                        'master_class_booked',
                        'Student booked a Master Class at '.AppClock::formatTime($startsAt).' ('.$remaining.' left this month)',
                        related: $booking,
                        meta: ['remaining' => $remaining],
                    );
                } else {
                    StudentActivity::record(
                        $student,
                        'introduction_booked',
                        'Student booked an Introduction Call at '.AppClock::formatTime($startsAt),
                        related: $booking,
                    );
                }

                return $booking;
            });
        } catch (Throwable $error) {
            $this->notifyAdmins->execute(
                $student,
                $teacher,
                $error,
                'book',
                ['date' => $date, 'start' => $start, 'type' => $type->value],
            );

            throw $error;
        }
    }

    private function assertSlot(string $start, string $date): void
    {
        if (! SlotGrid::isAligned($start)) {
            throw new ApiException(ErrorCode::VALIDATION_ERROR, 'Invalid time slot.', 422);
        }

        $startsAt = SlotGrid::atDate($date, $start);
        if ($startsAt->lte(AppClock::now())) {
            throw new ApiException(ErrorCode::VALIDATION_ERROR, 'Bookings must be in the future.', 422);
        }
    }

    private function assertEligibility(StudentProfile $student, TeacherProfile $teacher, SessionBookingType $type): bool
    {
        if (! $this->eligibility->teacherIsEligible($student, $teacher)) {
            throw new ApiException(ErrorCode::TEACHER_NOT_ELIGIBLE, 'This teacher is not assigned to the student\'s level.', 422);
        }

        if ($type === SessionBookingType::IntroductionCall) {
            $state = $this->eligibility->forStudent($student);
            if (! $state['can_book_introduction']) {
                throw new ApiException(
                    ErrorCode::CONFLICT,
                    $state['introduction_completed']
                        ? 'Introduction Call is already completed.'
                        : 'Your last Introduction Call chance has already been used, or you already have a booking.',
                    409,
                );
            }

            return $this->attendance->unusedRebookingFor($student->id, SessionBookingType::IntroductionCall) !== null
                && (int) $state['introduction_attempts_used'] >= 2;
        }

        if (! $this->eligibility->introductionCompleted($student)) {
            throw new ApiException(
                ErrorCode::INTRODUCTION_REQUIRED,
                'Complete your Introduction Call before booking a Master Class.',
                422,
            );
        }

        if (! $this->eligibility->canBookMasterClass($student)) {
            $balance = $this->masterClassBalance->snapshot($student);
            throw new ApiException(
                ErrorCode::MASTER_CLASS_MONTHLY_LIMIT,
                $balance['remaining'] < 1
                    ? 'No Master Class remaining this month. Book again next month, or after admin restores a class.'
                    : 'You already have a Master Class booked. Finish or update that one first.',
                422,
            );
        }

        return $this->attendance->unusedRebookingFor($student->id, SessionBookingType::MasterClass) !== null;
    }
}
