<?php

namespace App\Actions\Feedback;

use App\Enums\FeedbackTargetType;
use App\Enums\SessionBookingStatus;
use App\Enums\SessionBookingType;
use App\Exceptions\ApiException;
use App\Models\Dimension;
use App\Models\MonthlyFeedback;
use App\Models\MonthlyFeedbackItem;
use App\Models\SessionBooking;
use App\Models\StudentProfile;
use App\Models\TeacherProfile;
use App\Support\AppClock;
use App\Support\ErrorCode;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class CreateMonthlyFeedback
{
    /**
     * @param  array<string, mixed>  $input
     */
    public function execute(TeacherProfile $teacher, StudentProfile $student, array $input): MonthlyFeedback
    {
        $booking = $this->resolveBooking($teacher, $student, $input);
        $this->assertDimensionItems($input['items'] ?? []);

        $sessionDate = $booking->date?->timezone(config('app.timezone'))->startOfDay()
            ?? AppClock::now()->startOfDay();

        try {
            return DB::transaction(function () use ($teacher, $student, $input, $booking, $sessionDate) {
                $feedback = MonthlyFeedback::query()->create([
                    'student_id' => $student->id,
                    'master_teacher_id' => $teacher->id,
                    'session_booking_id' => $booking->id,
                    'year' => $sessionDate->year,
                    'month' => $sessionDate->month,
                    'session_date' => $sessionDate->toDateString(),
                    'positive_points' => $input['positive_points'] ?? null,
                    'areas_for_improvement' => $input['areas_for_improvement'] ?? null,
                    'discussed_in_class' => $input['discussed_in_class'] ?? null,
                    'submitted_at' => now(),
                ]);

                $this->storeItems($feedback, $input['items']);

                return $feedback->fresh(['items', 'masterTeacher', 'student', 'booking']) ?? $feedback;
            });
        } catch (UniqueConstraintViolationException) {
            throw new ApiException(
                ErrorCode::FEEDBACK_DUPLICATE,
                'This Master Class already has a rating. Edit the existing rating instead.',
                409,
            );
        }
    }

    /**
     * @param  array<string, mixed>  $input
     */
    private function resolveBooking(TeacherProfile $teacher, StudentProfile $student, array $input): SessionBooking
    {
        $bookingId = $input['booking_id'] ?? null;
        $query = SessionBooking::query()
            ->where('student_id', $student->id)
            ->where('teacher_id', $teacher->id)
            ->where('type', SessionBookingType::MasterClass->value)
            ->where('status', '!=', SessionBookingStatus::Cancelled->value)
            ->where('ends_at', '<=', AppClock::now())
            ->whereDoesntHave('attendanceIssues')
            ->whereDoesntHave('monthlyFeedback');

        if (is_string($bookingId) && $bookingId !== '') {
            $booking = SessionBooking::query()->whereKey($bookingId)->first();
            if ($booking === null
                || $booking->student_id !== $student->id
                || $booking->teacher_id !== $teacher->id
                || ($booking->type?->value ?? $booking->type) !== SessionBookingType::MasterClass->value
                || ($booking->status?->value ?? $booking->status) === SessionBookingStatus::Cancelled->value
            ) {
                throw new ApiException(ErrorCode::VALIDATION_ERROR, 'Choose a completed Master Class to rate.', 422);
            }
            if ($booking->monthlyFeedback()->exists()) {
                throw new ApiException(
                    ErrorCode::FEEDBACK_DUPLICATE,
                    'This Master Class already has a rating. Edit the existing rating instead.',
                    409,
                );
            }

            return $booking;
        }

        $booking = $query->orderBy('starts_at')->first();
        if ($booking === null) {
            throw new ApiException(
                ErrorCode::FEEDBACK_NOT_DUE,
                'Add a rating only after this student completes a Master Class with you.',
                409,
            );
        }

        return $booking;
    }

    /**
     * @param  list<array<string, mixed>>  $items
     */
    public function assertDimensionItems(array $items): void
    {
        $dimensionIds = Dimension::query()->orderBy('display_order')->pluck('id');
        $seen = [];

        foreach ($items as $index => $item) {
            $type = FeedbackTargetType::tryFrom((string) ($item['target_type'] ?? ''));
            $targetId = (string) ($item['target_id'] ?? '');
            if ($type !== FeedbackTargetType::Dimension || ! $dimensionIds->contains($targetId)) {
                throw ValidationException::withMessages([
                    "items.{$index}.target_id" => 'Rate each of the ten development dimensions.',
                ]);
            }
            if (isset($seen[$targetId])) {
                throw ValidationException::withMessages([
                    "items.{$index}.target_id" => 'Each dimension can only be rated once.',
                ]);
            }
            $seen[$targetId] = true;
        }

        if (count($seen) !== $dimensionIds->count()) {
            throw ValidationException::withMessages([
                'items' => 'Rate all ten dimensions for this Master Class.',
            ]);
        }
    }

    /**
     * @param  list<array<string, mixed>>  $items
     */
    public function storeItems(MonthlyFeedback $feedback, array $items): void
    {
        foreach ($items as $item) {
            MonthlyFeedbackItem::query()->create([
                'monthly_feedback_id' => $feedback->id,
                'target_type' => FeedbackTargetType::Dimension->value,
                'target_id' => $item['target_id'],
                'rating' => $item['rating'],
            ]);
        }
    }
}
