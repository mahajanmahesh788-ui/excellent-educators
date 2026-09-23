<?php

namespace App\Actions\Scheduling;

use App\Actions\Notifications\NotifyAdminsOfStudentBookingFailure;
use App\Enums\SessionBookingStatus;
use App\Enums\SessionBookingType;
use App\Exceptions\ApiException;
use App\Meetings\TeacherDailyMeetingService;
use App\Models\SessionBooking;
use App\Models\TeacherProfile;
use App\Scheduling\AvailabilityCalculator;
use App\Scheduling\BookingEligibility;
use App\Scheduling\SlotGrid;
use App\Support\AppClock;
use App\Support\ErrorCode;
use App\Support\StudentActivity;
use Illuminate\Support\Facades\DB;
use Throwable;

class RescheduleSessionBooking
{
    public function __construct(
        private readonly AvailabilityCalculator $availability,
        private readonly BookingEligibility $eligibility,
        private readonly TeacherDailyMeetingService $meetings,
        private readonly NotifyAdminsOfStudentBookingFailure $notifyAdmins,
    ) {}

    /**
     * @param  array<string, mixed>  $payload
     */
    public function execute(SessionBooking $booking, array $payload, bool $adminOverride = false): SessionBooking
    {
        if ($booking->status === SessionBookingStatus::Cancelled) {
            throw new ApiException(ErrorCode::CONFLICT, 'Cancelled bookings cannot be rescheduled.', 409);
        }

        $teacher = TeacherProfile::query()->findOrFail($payload['teacher_id'] ?? $booking->teacher_id);
        $date = (string) ($payload['date'] ?? $booking->date?->toDateString());
        $start = (string) $payload['start'];
        $student = $booking->student;

        try {
            if (! in_array($start, SlotGrid::starts(), true)) {
                throw new ApiException(ErrorCode::VALIDATION_ERROR, 'Invalid time slot.', 422);
            }

            $startsAt = SlotGrid::atDate($date, $start);
            if ($startsAt->lte(AppClock::now())) {
                throw new ApiException(ErrorCode::VALIDATION_ERROR, 'Bookings must be in the future.', 422);
            }

            if (! $adminOverride) {
                if (! $this->eligibility->teacherIsEligible($student, $teacher)) {
                    throw new ApiException(ErrorCode::TEACHER_NOT_ELIGIBLE, 'This teacher is not assigned to the student\'s level.', 422);
                }
                if ($booking->type === SessionBookingType::MasterClass
                    && ! $this->eligibility->canBookMasterClass($student, $booking->id)) {
                    throw new ApiException(
                        ErrorCode::MASTER_CLASS_MONTHLY_LIMIT,
                        'This Master Class is already used for this month.',
                        422,
                    );
                }
            }

            return DB::transaction(function () use ($booking, $teacher, $date, $start, $startsAt): SessionBooking {
                SessionBooking::query()
                    ->where('teacher_id', $teacher->id)
                    ->whereDate('date', $date)
                    ->lockForUpdate()
                    ->get();

                if (! $this->availability->isSlotAvailable($teacher, $date, $start, $booking->id)) {
                    throw new ApiException(ErrorCode::SLOT_UNAVAILABLE, 'This time slot is no longer available.', 409);
                }

                $endsAt = $startsAt->copy()->addMinutes(SlotGrid::slotMinutes());
                $overlap = SessionBooking::query()
                    ->where('teacher_id', $teacher->id)
                    ->where('id', '!=', $booking->id)
                    ->where('status', '!=', SessionBookingStatus::Cancelled->value)
                    ->where('starts_at', '<', $endsAt)
                    ->where('ends_at', '>', $startsAt)
                    ->exists();

                if ($overlap) {
                    throw new ApiException(ErrorCode::BOOKING_OVERLAP, 'This teacher already has a booking in that time.', 409);
                }

                $this->meetings->getOrCreate($teacher, $date);

                $from = AppClock::formatTime($booking->starts_at);
                $booking->update([
                    'teacher_id' => $teacher->id,
                    'date' => $date,
                    'starts_at' => $startsAt,
                    'ends_at' => $endsAt,
                    'status' => SessionBookingStatus::Scheduled->value,
                ]);

                $label = SessionBookingType::fromMixed($booking->type)?->label() ?? 'Introduction Call';
                $to = AppClock::formatTime($startsAt);
                StudentActivity::record(
                    $booking->student,
                    $booking->type === SessionBookingType::MasterClass ? 'master_class_rescheduled' : 'introduction_rescheduled',
                    "Student updated the {$label} time from {$from} to {$to}",
                    related: $booking,
                );

                return $booking->fresh(['student', 'teacher']) ?? $booking;
            });
        } catch (Throwable $error) {
            $this->notifyAdmins->execute(
                $student,
                $teacher,
                $error,
                'reschedule',
                [
                    'date' => $date,
                    'start' => $start,
                    'type' => SessionBookingType::fromMixed($booking->type)?->value,
                    'booking_id' => $booking->id,
                ],
            );

            throw $error;
        }
    }
}
