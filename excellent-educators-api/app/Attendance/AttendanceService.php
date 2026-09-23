<?php

namespace App\Attendance;

use App\Enums\AttendanceDecision;
use App\Enums\AttendanceIssueType;
use App\Enums\AttendanceVerificationStatus;
use App\Enums\JoinActorType;
use App\Enums\RoleName;
use App\Enums\SessionBookingStatus;
use App\Enums\SessionBookingType;
use App\Exceptions\ApiException;
use App\Models\AttendanceIssue;
use App\Models\ClassAttendance;
use App\Models\ClassJoinEvent;
use App\Models\MonthlyFeedback;
use App\Models\SessionBooking;
use App\Models\TeacherDailyMeeting;
use App\Models\User;
use App\Scheduling\BookingEligibility;
use App\Scheduling\MasterClassBalance;
use App\Support\AppClock;
use App\Support\ErrorCode;
use App\Support\PhoneNumber;
use App\Support\StudentActivity;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Support\Facades\DB;

class AttendanceService
{
    public function recordJoin(SessionBooking $booking, JoinActorType $actor, string $actorId): ClassAttendance
    {
        $now = AppClock::now();
        $this->assertJoinWindow($booking, $actor, $now);

        return DB::transaction(function () use ($booking, $actor, $actorId, $now): ClassAttendance {
            $attendance = $this->lockAttendance($booking);

            ClassJoinEvent::query()->create([
                'booking_id' => $booking->id,
                'actor_type' => $actor->value,
                'actor_id' => $actorId,
                'joined_at' => $now,
            ]);

            if ($actor === JoinActorType::Student) {
                $firstJoin = $attendance->student_first_join_at === null;
                $attendance->update([
                    'student_first_join_at' => $attendance->student_first_join_at ?? $now,
                    'student_last_join_at' => $now,
                    'student_join_count' => $attendance->student_join_count + 1,
                ]);
                if ($firstJoin && $booking->student) {
                    $type = SessionBookingType::fromMixed($booking->type);
                    $label = $type?->label() ?? 'Introduction Call';
                    $time = AppClock::formatTime($booking->starts_at);
                    StudentActivity::record(
                        $booking->student,
                        $type === SessionBookingType::MasterClass
                            ? 'master_class_attended'
                            : 'introduction_attended',
                        "Student attended {$label}".($time !== '' ? " at {$time}" : ''),
                        related: $booking,
                    );
                }
            } else {
                $attendance->update([
                    'teacher_first_join_at' => $attendance->teacher_first_join_at ?? $now,
                    'teacher_last_join_at' => $now,
                    'teacher_join_count' => $attendance->teacher_join_count + 1,
                ]);
                $this->stampTeacherDayMeet($booking, $now);
            }

            return $attendance->fresh() ?? $attendance;
        });
    }

    /**
     * @return array<string, mixed>
     */
    public function teacherWhatsAppReminder(SessionBooking $booking): array
    {
        $booking->loadMissing(['student', 'teacher']);
        $now = AppClock::now();
        $starts = $booking->starts_at?->timezone(config('app.timezone'));
        $ends = $booking->ends_at?->timezone(config('app.timezone'));

        if ($booking->status === SessionBookingStatus::Cancelled) {
            throw new ApiException(ErrorCode::WHATSAPP_WINDOW, 'This class is cancelled.', 422);
        }

        if ($starts === null || $ends === null || $now->lt($starts)) {
            throw new ApiException(ErrorCode::WHATSAPP_WINDOW, 'Available when class starts', 422);
        }

        if ($now->gte($ends)) {
            throw new ApiException(ErrorCode::WHATSAPP_WINDOW, 'Class ended', 422);
        }

        $student = $booking->student;
        $teacher = $booking->teacher;
        $rawPhone = filled($student?->whatsapp_number) ? $student->whatsapp_number : $student?->phone;
        $digits = PhoneNumber::whatsAppDigits($rawPhone);
        if ($digits === null) {
            throw new ApiException(
                ErrorCode::STUDENT_WHATSAPP_UNAVAILABLE,
                'Student WhatsApp number is not available.',
                422,
            );
        }

        $studentName = (string) ($student?->full_name ?: 'Student');
        $teacherName = (string) ($teacher?->full_name ?: 'your teacher');
        $loginUrl = rtrim((string) config('app.frontend_url'), '/').'/login';
        $message = "Hi {$studentName},\n\n"
            ."Your scheduled class with {$teacherName} is currently in progress.\n"
            ."I'm waiting for you to join the class.\n\n"
            ."Please log in to your Excellent Educators account and join your scheduled class:\n\n"
            ."{$loginUrl}\n\n"
            .'Thank you.';

        $attendance = $this->ensureAttendance($booking);
        if ($attendance->teacher_whatsapp_reminder_sent_at === null) {
            $attendance->update(['teacher_whatsapp_reminder_sent_at' => $now]);
        }

        return [
            'whatsapp_url' => 'https://wa.me/'.$digits.'?text='.rawurlencode($message),
            'message' => $message,
            'student_name' => $studentName,
            'teacher_name' => $teacherName,
            'login_url' => $loginUrl,
            'phone' => $digits,
            'teacher_whatsapp_reminder_sent_at' => ($attendance->fresh()?->teacher_whatsapp_reminder_sent_at ?? $now)
                ->timezone(config('app.timezone'))
                ->toIso8601String(),
        ];
    }

    public function report(SessionBooking $booking, User $reporter, AttendanceIssueType $type, string $message): AttendanceIssue
    {
        $now = AppClock::now();
        $ends = $booking->ends_at?->timezone(config('app.timezone'));
        if ($ends === null || $now->lt($ends)) {
            throw new ApiException(
                ErrorCode::ATTENDANCE_REPORT_TOO_EARLY,
                'Attendance issues can be reported after the class ends.',
                422,
            );
        }
        if (! $this->withinAbsenceReportWindow($ends, $now)) {
            throw new ApiException(
                ErrorCode::ATTENDANCE_REPORT_TOO_LATE,
                'This report can only be submitted within 1 hour after the class ends.',
                422,
            );
        }

        $attendance = $this->ensureAttendance($booking);
        $role = $reporter->hasRole(RoleName::Student->value) ? 'student' : 'teacher';

        if ($type === AttendanceIssueType::TeacherDidNotJoin) {
            if ($role !== 'student' || $booking->student_id !== $reporter->studentProfile?->id) {
                throw new ApiException(ErrorCode::FORBIDDEN, 'You can only report your own class.', 403);
            }
        }

        if ($type === AttendanceIssueType::StudentDidNotJoin) {
            if ($role !== 'teacher' || $booking->teacher_id !== $reporter->teacherProfile?->id) {
                throw new ApiException(ErrorCode::FORBIDDEN, 'You can only report your own class.', 403);
            }
            if ((int) $attendance->student_join_count > 0) {
                throw new ApiException(
                    ErrorCode::ATTENDANCE_REPORT_NOT_ALLOWED,
                    'The student has a join attempt recorded for this class.',
                    422,
                );
            }
        }

        $trimmed = trim($message);
        if ($trimmed === '') {
            throw new ApiException(ErrorCode::VALIDATION_ERROR, 'Please describe what happened.', 422);
        }

        try {
            return AttendanceIssue::query()->create([
                'booking_id' => $booking->id,
                'reporter_user_id' => $reporter->id,
                'reporter_role' => $role,
                'issue_type' => $type->value,
                'message' => $trimmed,
                'verification_status' => AttendanceVerificationStatus::Pending->value,
            ]);
        } catch (UniqueConstraintViolationException) {
            throw new ApiException(
                ErrorCode::ATTENDANCE_REPORT_DUPLICATE,
                'This attendance issue has already been reported for this class.',
                409,
            );
        }
    }

    public function resolve(AttendanceIssue $issue, User $admin, AttendanceDecision $decision, ?string $notes): AttendanceIssue
    {
        if (! $issue->isPending()) {
            throw new ApiException(ErrorCode::CONFLICT, 'This report has already been reviewed.', 409);
        }

        return DB::transaction(function () use ($issue, $admin, $decision, $notes): AttendanceIssue {
            $issue->loadMissing('booking.student');
            $issue->update([
                'verification_status' => AttendanceVerificationStatus::Resolved->value,
                'admin_decision' => $decision->value,
                'admin_notes' => filled($notes) ? trim((string) $notes) : null,
                'verified_by' => $admin->id,
                'verified_at' => AppClock::now(),
            ]);

            if (in_array($decision, [
                AttendanceDecision::TeacherAbsent,
                AttendanceDecision::TechnicalIssue,
                AttendanceDecision::StudentAbsent,
                AttendanceDecision::BothAbsent,
                AttendanceDecision::ExtraChance,
            ], true)) {
                $attendance = $this->ensureAttendance($issue->booking);
                if (! $attendance->rebooking_granted) {
                    $attendance->update([
                        'rebooking_granted' => true,
                        'rebooking_granted_at' => AppClock::now(),
                    ]);
                }
                $booking = $issue->booking;
                if ($booking !== null && ($booking->type?->value ?? $booking->type) === SessionBookingType::MasterClass->value && $booking->student) {
                    $balance = app(MasterClassBalance::class);
                    $balance->restore($booking->student);
                    $remaining = $balance->remaining($booking->student);
                    StudentActivity::record(
                        $booking->student,
                        'master_class_credit_restored',
                        "Admin restored a Master Class. Remaining this month: {$remaining}",
                        actor: $admin,
                        related: $booking,
                        meta: ['remaining' => $remaining, 'decision' => $decision->value],
                    );
                }
            }

            if (in_array($decision, [AttendanceDecision::BothAttended, AttendanceDecision::StudentAttended], true)) {
                $issue->booking?->update(['status' => SessionBookingStatus::Completed->value]);
            }

            return $issue->fresh(['booking.student', 'booking.teacher', 'reporter', 'verifier']) ?? $issue;
        });
    }

    public function consumeRebooking(string $studentId, SessionBooking $replacement): void
    {
        $type = $replacement->type instanceof SessionBookingType
            ? $replacement->type
            : SessionBookingType::from((string) $replacement->type);
        $credit = $this->unusedRebookingFor($studentId, $type);
        $credit?->update(['replacement_booking_id' => $replacement->id]);
    }

    public function unusedRebookingFor(string $studentId, ?SessionBookingType $type = null): ?ClassAttendance
    {
        return ClassAttendance::query()
            ->where('student_id', $studentId)
            ->where('rebooking_granted', true)
            ->whereNull('replacement_booking_id')
            ->when($type, function ($query) use ($type): void {
                $query->whereHas('booking', fn ($booking) => $booking->where('type', $type->value));
            })
            ->orderBy('rebooking_granted_at')
            ->first();
    }

    /**
     * @return array<string, mixed>
     */
    public function payloadFor(SessionBooking $booking, string $viewer): array
    {
        $now = AppClock::now();
        $attendance = ClassAttendance::query()->where('booking_id', $booking->id)->first();
        $dayMeet = TeacherDailyMeeting::query()
            ->where('teacher_id', $booking->teacher_id)
            ->whereDate('date', $booking->date?->toDateString())
            ->first();
        $issues = AttendanceIssue::query()->where('booking_id', $booking->id)->orderBy('created_at')->get();
        $starts = $booking->starts_at?->timezone(config('app.timezone'));
        $ends = $booking->ends_at?->timezone(config('app.timezone'));
        $joinLead = (int) config('excellent_educators.attendance.join_lead_minutes', 2);
        $studentJoinOpen = $starts !== null
            && $ends !== null
            && $now->gte($starts->copy()->subMinutes($joinLead))
            && $now->lt($ends);
        $classEnded = $ends !== null && $now->gte($ends);
        $studentJoined = (int) ($attendance?->student_join_count ?? 0) > 0;
        $pending = $issues->first(fn (AttendanceIssue $issue) => $issue->isPending());
        if ($classEnded && $studentJoined && $pending === null && $booking->status === SessionBookingStatus::Scheduled) {
            $booking->update(['status' => SessionBookingStatus::Completed->value]);
            $booking->refresh();
        }
        $canStudentJoin = $viewer === 'student' && $booking->status === SessionBookingStatus::Scheduled && $studentJoinOpen;
        $canTeacherJoin = $viewer === 'teacher' && $booking->status !== SessionBookingStatus::Cancelled;
        $canReportTeacher = $viewer === 'student'
            && $this->withinAbsenceReportWindow($ends, $now)
            && ! $issues->contains(
                fn (AttendanceIssue $issue) => $issue->issue_type === AttendanceIssueType::TeacherDidNotJoin,
            );
        $canReportStudent = $viewer === 'teacher'
            && $this->withinAbsenceReportWindow($ends, $now)
            && ! $studentJoined
            && ! $issues->contains(
                fn (AttendanceIssue $issue) => $issue->issue_type === AttendanceIssueType::StudentDidNotJoin,
            );
        $isMasterClass = $booking->type === SessionBookingType::MasterClass;
        $existingRating = null;
        if ($isMasterClass && $booking->student_id && $booking->teacher_id && $booking->date) {
            $existingRating = MonthlyFeedback::query()
                ->where('session_booking_id', $booking->id)
                ->first();
        }
        $ratingEligible = $viewer === 'teacher'
            && $isMasterClass
            && $classEnded
            && $studentJoined
            && $pending === null;
        $canRate = $ratingEligible && $existingRating === null;
        $canEditRating = $ratingEligible && $existingRating !== null;
        $completedUi = $booking->status === SessionBookingStatus::Completed
            || ($classEnded && $studentJoined && $pending === null);

        $canWhatsApp = $viewer === 'teacher'
            && $booking->status !== SessionBookingStatus::Cancelled
            && $starts !== null
            && $ends !== null
            && $now->gte($starts)
            && $now->lt($ends);
        $whatsAppWindow = 'unavailable';
        $whatsAppHint = null;
        if ($booking->status === SessionBookingStatus::Cancelled) {
            $whatsAppWindow = 'unavailable';
            $whatsAppHint = 'Class cancelled';
        } elseif ($starts !== null && $now->lt($starts)) {
            $whatsAppWindow = 'before';
            $whatsAppHint = 'Available when class starts';
        } elseif ($ends !== null && $now->gte($ends)) {
            $whatsAppWindow = 'after';
            $whatsAppHint = 'Class ended';
        } elseif ($canWhatsApp) {
            $whatsAppWindow = 'during';
        }

        return [
            'student_first_join_at' => $attendance?->student_first_join_at?->timezone(config('app.timezone'))->toIso8601String(),
            'student_last_join_at' => $attendance?->student_last_join_at?->timezone(config('app.timezone'))->toIso8601String(),
            'student_join_count' => (int) ($attendance?->student_join_count ?? 0),
            'teacher_booking_join_count' => (int) ($attendance?->teacher_join_count ?? 0),
            'teacher_booking_first_join_at' => $attendance?->teacher_first_join_at?->timezone(config('app.timezone'))->toIso8601String(),
            'teacher_day_join_at' => $dayMeet?->first_join_at?->timezone(config('app.timezone'))->toIso8601String(),
            'teacher_day_join_count' => (int) ($dayMeet?->join_count ?? 0),
            'join_opens_at' => $starts?->copy()->subMinutes($joinLead)->toIso8601String(),
            'can_join' => $canStudentJoin || $canTeacherJoin,
            'can_report_teacher_did_not_join' => $canReportTeacher,
            'can_report_student_did_not_join' => $canReportStudent,
            'can_rate_student' => $canRate,
            'can_edit_student_rating' => $canEditRating,
            'monthly_feedback_id' => $existingRating?->id,
            'can_whatsapp_student' => $canWhatsApp,
            'whatsapp_window' => $whatsAppWindow,
            'whatsapp_hint' => $whatsAppHint,
            'teacher_whatsapp_reminder_sent_at' => $attendance?->teacher_whatsapp_reminder_sent_at?->timezone(config('app.timezone'))->toIso8601String(),
            'class_completed' => $completedUi,
            'pending_issue' => $pending !== null,
            'report_submitted' => $issues->isNotEmpty(),
            'rebooking_available' => (bool) ($attendance?->hasUnusedRebooking()),
            'is_last_chance' => $this->isLastChance($booking),
            'last_chance_message' => $this->lastChanceMessage($booking),
            'issues' => $issues->map(fn (AttendanceIssue $issue) => [
                'id' => $issue->id,
                'issue_type' => $issue->issue_type?->value ?? $issue->issue_type,
                'message' => $issue->message,
                'reporter_role' => $issue->reporter_role,
                'verification_status' => $issue->verification_status?->value ?? $issue->verification_status,
                'admin_decision' => $issue->admin_decision?->value ?? $issue->admin_decision,
            ])->values()->all(),
        ];
    }

    /**
     * @return array<string, int>
     */
    public function dashboardCounts(?int $year = null, ?int $month = null): array
    {
        $bookingFilter = function ($query) use ($year, $month): void {
            if ($year !== null && $month !== null) {
                $query->whereYear('date', $year)->whereMonth('date', $month);
            }
        };

        $issueFilter = function ($query) use ($year, $month): void {
            if ($year !== null && $month !== null) {
                $query->whereYear('created_at', $year)->whereMonth('created_at', $month);
            }
        };

        $attendanceFilter = function ($query) use ($year, $month): void {
            if ($year !== null && $month !== null) {
                $query->whereYear('rebooking_granted_at', $year)->whereMonth('rebooking_granted_at', $month);
            }
        };

        return [
            'total_classes' => SessionBooking::query()->where('status', '!=', SessionBookingStatus::Cancelled->value)->where($bookingFilter)->count(),
            'completed_classes' => SessionBooking::query()->where('status', SessionBookingStatus::Completed->value)->where($bookingFilter)->count(),
            'pending_verification' => AttendanceIssue::query()->where('verification_status', AttendanceVerificationStatus::Pending->value)->where($issueFilter)->count(),
            'student_attendance_reports' => AttendanceIssue::query()->where('reporter_role', 'student')->where($issueFilter)->count(),
            'teacher_attendance_reports' => AttendanceIssue::query()->where('reporter_role', 'teacher')->where($issueFilter)->count(),
            'verified_teacher_absence' => AttendanceIssue::query()->where('admin_decision', AttendanceDecision::TeacherAbsent->value)->where($issueFilter)->count(),
            'verified_student_absence' => AttendanceIssue::query()->where('admin_decision', AttendanceDecision::StudentAbsent->value)->where($issueFilter)->count(),
            'technical_issues' => AttendanceIssue::query()->where('admin_decision', AttendanceDecision::TechnicalIssue->value)->where($issueFilter)->count(),
            'rebookings_given' => ClassAttendance::query()->where('rebooking_granted', true)->where($attendanceFilter)->count(),
        ];
    }

    /**
     * @return array<string, mixed>
     */
    public function issueDetail(AttendanceIssue $issue): array
    {
        $issue->loadMissing([
            'booking.student.academicLevel',
            'booking.student.activeEnrollment.batch.level',
            'booking.teacher',
            'reporter',
            'verifier',
        ]);
        $booking = $issue->booking;
        $attendance = $booking ? ClassAttendance::query()->where('booking_id', $booking->id)->first() : null;
        $dayMeet = $booking ? TeacherDailyMeeting::query()
            ->where('teacher_id', $booking->teacher_id)
            ->whereDate('date', $booking->date?->toDateString())
            ->first() : null;
        $sibling = AttendanceIssue::query()->where('booking_id', $issue->booking_id)->orderBy('created_at')->get();
        $type = $booking?->type?->value ?? $booking?->type;
        $eligibility = $booking ? app(BookingEligibility::class) : null;
        $student = $booking?->student;
        $levelName = $student?->academicLevel?->name
            ?? $student?->activeEnrollment?->batch?->level?->name;

        return [
            'id' => $issue->id,
            'student_name' => $booking?->student?->full_name,
            'teacher_name' => $booking?->teacher?->full_name,
            'student_id' => $booking?->student_id,
            'teacher_id' => $booking?->teacher_id,
            'booking_id' => $issue->booking_id,
            'booking_type' => $type,
            'attempt_number' => $booking && $eligibility ? $eligibility->attemptNumber($booking) : null,
            'learning_week' => $booking && $eligibility && $type === 'master_class'
                ? $eligibility->learningWeekFor($booking)
                : null,
            'level_name' => $levelName,
            'date' => $booking?->date?->toDateString(),
            'start' => $booking?->starts_at?->timezone(config('app.timezone'))->format('H:i'),
            'end' => $booking?->ends_at?->timezone(config('app.timezone'))->format('H:i'),
            'issue_type' => $issue->issue_type?->value ?? $issue->issue_type,
            'reporter_role' => $issue->reporter_role,
            'message' => $issue->message,
            'created_at' => $issue->created_at?->timezone(config('app.timezone'))->toIso8601String(),
            'verification_status' => $issue->verification_status?->value ?? $issue->verification_status,
            'admin_decision' => $issue->admin_decision?->value ?? $issue->admin_decision,
            'admin_notes' => $issue->admin_notes,
            'verified_at' => $issue->verified_at?->timezone(config('app.timezone'))->toIso8601String(),
            'verified_by_name' => $issue->verifier?->name,
            'meeting_url' => $dayMeet?->meet_url,
            'student_first_join_at' => $attendance?->student_first_join_at?->timezone(config('app.timezone'))->toIso8601String(),
            'student_last_join_at' => $attendance?->student_last_join_at?->timezone(config('app.timezone'))->toIso8601String(),
            'student_join_count' => (int) ($attendance?->student_join_count ?? 0),
            'teacher_booking_join_count' => (int) ($attendance?->teacher_join_count ?? 0),
            'teacher_day_join_at' => $dayMeet?->first_join_at?->timezone(config('app.timezone'))->toIso8601String(),
            'teacher_day_join_count' => (int) ($dayMeet?->join_count ?? 0),
            'rebooking_granted' => (bool) ($attendance?->rebooking_granted),
            'rebooking_used' => $attendance?->replacement_booking_id !== null,
            'reports' => $sibling->map(fn (AttendanceIssue $item) => [
                'id' => $item->id,
                'issue_type' => $item->issue_type?->value ?? $item->issue_type,
                'reporter_role' => $item->reporter_role,
                'message' => $item->message,
                'created_at' => $item->created_at?->timezone(config('app.timezone'))->toIso8601String(),
            ])->values()->all(),
        ];
    }

    public function pruneJoinEvents(): int
    {
        $cutoff = AppClock::now()->subDays((int) config('excellent_educators.attendance.join_event_retain_days', 2));
        $disputed = AttendanceIssue::query()->pluck('booking_id');

        return ClassJoinEvent::query()
            ->where('joined_at', '<', $cutoff)
            ->whereNotIn('booking_id', $disputed)
            ->delete();
    }

    private function assertJoinWindow(SessionBooking $booking, JoinActorType $actor, $now): void
    {
        if ($booking->status === SessionBookingStatus::Cancelled) {
            throw new ApiException(ErrorCode::CONFLICT, 'This class is cancelled.', 409);
        }

        if ($actor === JoinActorType::Teacher) {
            return;
        }

        $starts = $booking->starts_at?->timezone(config('app.timezone'));
        $ends = $booking->ends_at?->timezone(config('app.timezone'));
        $lead = (int) config('excellent_educators.attendance.join_lead_minutes', 2);
        if ($starts === null || $now->lt($starts->copy()->subMinutes($lead))) {
            throw new ApiException(
                ErrorCode::JOIN_TOO_EARLY,
                'Join Class is available 2 minutes before the scheduled start.',
                422,
            );
        }
        if ($ends !== null && $now->gte($ends)) {
            throw new ApiException(
                ErrorCode::JOIN_TOO_LATE,
                'This session has ended.',
                422,
            );
        }
    }

    private function withinAbsenceReportWindow(mixed $ends, mixed $now): bool
    {
        if ($ends === null || $now === null) {
            return false;
        }
        $minutes = (int) config('excellent_educators.attendance.absence_report_minutes', 60);

        return $now->gte($ends) && $now->lte($ends->copy()->addMinutes($minutes));
    }

    private function lockAttendance(SessionBooking $booking): ClassAttendance
    {
        $existing = ClassAttendance::query()->where('booking_id', $booking->id)->lockForUpdate()->first();
        if ($existing !== null) {
            return $existing;
        }

        return $this->ensureAttendance($booking);
    }

    private function ensureAttendance(SessionBooking $booking): ClassAttendance
    {
        return ClassAttendance::query()->firstOrCreate(
            ['booking_id' => $booking->id],
            [
                'student_id' => $booking->student_id,
                'teacher_id' => $booking->teacher_id,
            ],
        );
    }

    private function stampTeacherDayMeet(SessionBooking $booking, $now): void
    {
        $meet = TeacherDailyMeeting::query()
            ->where('teacher_id', $booking->teacher_id)
            ->whereDate('date', $booking->date?->toDateString())
            ->lockForUpdate()
            ->first();
        if ($meet === null) {
            return;
        }
        $meet->update([
            'first_join_at' => $meet->first_join_at ?? $now,
            'last_join_at' => $now,
            'join_count' => (int) $meet->join_count + 1,
        ]);
    }

    private function isLastChance(SessionBooking $booking): bool
    {
        $type = $booking->type?->value ?? $booking->type;
        $attempt = app(BookingEligibility::class)->attemptNumber($booking) ?? 1;
        if ($type === SessionBookingType::IntroductionCall->value) {
            return $attempt >= 2;
        }
        if ($type === SessionBookingType::MasterClass->value) {
            $student = $booking->student ?? $booking->student()->first();
            if ($student === null) {
                return false;
            }
            $balance = app(MasterClassBalance::class)->snapshot($student);
            if ((int) $balance['allotment'] > 1 || (int) $balance['remaining'] > 0) {
                return false;
            }

            return $attempt >= 2;
        }

        return false;
    }

    private function lastChanceMessage(SessionBooking $booking): ?string
    {
        if (! $this->isLastChance($booking)) {
            return null;
        }
        $type = $booking->type?->value ?? $booking->type;
        if ($type === SessionBookingType::IntroductionCall->value) {
            return 'This is your last chance to attend the Introduction Call. If this slot is missed, another interview cannot be booked.';
        }

        return 'This is your last Master Class chance for this month. If this slot is missed, another session cannot be booked until next month.';
    }
}
