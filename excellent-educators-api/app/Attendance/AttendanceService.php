<?php

namespace App\Attendance;

use App\Actions\Notifications\NotifyOperationalAdmins;
use App\Enums\AttendanceDecision;
use App\Enums\AttendanceIssueType;
use App\Enums\AttendanceVerificationStatus;
use App\Enums\JoinActorType;
use App\Enums\NotificationType;
use App\Enums\RoleName;
use App\Enums\SessionBookingStatus;
use App\Enums\SessionBookingType;
use App\Exceptions\ApiException;
use App\Models\AttendanceIssue;
use App\Models\ClassAttendance;
use App\Models\ClassJoinEvent;
use App\Models\MonthlyFeedback;
use App\Models\SessionBooking;
use App\Models\StudentMasterClassBalance;
use App\Models\TeacherDailyMeeting;
use App\Models\User;
use App\Actions\Notifications\CreateUserNotification;
use App\Scheduling\BookingEligibility;
use App\Scheduling\MasterClassBalance;
use App\Support\AppClock;
use App\Support\ErrorCode;
use App\Support\PhoneNumber;
use App\Support\StudentActivity;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Throwable;

class AttendanceService
{
    public function __construct(
        private readonly CreateUserNotification $notifications,
        private readonly NotifyOperationalAdmins $notifyAdmins,
    ) {}

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
            $isTeacherOfBooking = $role === 'teacher'
                && $booking->teacher_id !== null
                && $booking->teacher_id === $reporter->teacherProfile?->id;
            $isStudentOfBooking = $role === 'student'
                && $booking->student_id !== null
                && $booking->student_id === $reporter->studentProfile?->id;
            if (! $isTeacherOfBooking && ! $isStudentOfBooking) {
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
            $issue = AttendanceIssue::query()->create([
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

        $this->notifyAdminsOfReport($issue->fresh(['booking.student', 'booking.teacher']) ?? $issue, $reporter, $type);

        return $issue;
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

            $resolved = $issue->fresh(['booking.student', 'booking.teacher', 'reporter', 'verifier']) ?? $issue;
            $this->notifyReporterOfResolution($resolved, $decision);

            return $resolved;
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
        return $this->payloadsFor(collect([$booking]), $viewer)[$booking->id]
            ?? $this->emptyPayload();
    }

    /**
     * Batch attendance payloads for booking lists (avoids N+1 per booking).
     *
     * @param  \Illuminate\Support\Collection<int, SessionBooking>  $bookings
     * @return array<string, array<string, mixed>> keyed by booking id
     */
    public function payloadsFor($bookings, string $viewer): array
    {
        $bookings = collect($bookings)->filter(fn ($b) => $b instanceof SessionBooking && filled($b->id))->values();
        if ($bookings->isEmpty()) {
            return [];
        }

        $bookings = $bookings instanceof \Illuminate\Database\Eloquent\Collection
            ? $bookings
            : new \Illuminate\Database\Eloquent\Collection($bookings->all());

        $bookings->loadMissing([
            'student.academicLevel',
            'student.activeEnrollment.batch.level',
        ]);

        $ids = $bookings->pluck('id')->all();
        $attendances = ClassAttendance::query()
            ->whereIn('booking_id', $ids)
            ->get()
            ->keyBy('booking_id');
        $issuesByBooking = AttendanceIssue::query()
            ->whereIn('booking_id', $ids)
            ->orderBy('created_at')
            ->get()
            ->groupBy('booking_id');

        $teacherIds = $bookings->pluck('teacher_id')->filter()->unique()->values()->all();
        $dates = $bookings->map(fn (SessionBooking $b) => $this->dateKey($b->date))->filter()->unique()->values()->all();
        $dayMeets = $this->dayMeetsKeyedByTeacherDate($teacherIds, $dates);

        $feedbacks = MonthlyFeedback::query()
            ->whereIn('session_booking_id', $ids)
            ->get()
            ->keyBy('session_booking_id');

        $now = AppClock::now();
        $completeIds = [];
        foreach ($bookings as $booking) {
            $attendance = $attendances->get($booking->id);
            $issues = $issuesByBooking->get($booking->id, collect());
            $ends = $booking->ends_at?->timezone(config('app.timezone'));
            $classEnded = $ends !== null && $now->gte($ends);
            $studentJoined = (int) ($attendance?->student_join_count ?? 0) > 0;
            $pending = $issues->first(fn (AttendanceIssue $issue) => $issue->isPending());
            if ($classEnded && $studentJoined && $pending === null && $booking->status === SessionBookingStatus::Scheduled) {
                $completeIds[] = $booking->id;
            }
        }
        if ($completeIds !== []) {
            SessionBooking::query()
                ->whereIn('id', $completeIds)
                ->update(['status' => SessionBookingStatus::Completed->value]);
            foreach ($bookings as $booking) {
                if (in_array($booking->id, $completeIds, true)) {
                    $booking->status = SessionBookingStatus::Completed;
                }
            }
        }

        // Sibling bookings for attempt/last-chance (one query for the whole list).
        $studentIds = $bookings->pluck('student_id')->filter()->unique()->values()->all();
        $siblingsByStudentType = SessionBooking::query()
            ->whereIn('student_id', $studentIds)
            ->where('status', '!=', SessionBookingStatus::Cancelled->value)
            ->orderBy('starts_at')
            ->get(['id', 'student_id', 'type', 'starts_at', 'date', 'status'])
            ->groupBy(fn (SessionBooking $b) => $b->student_id.'|'.($b->type?->value ?? $b->type));

        $balances = $this->balanceHintsForStudents(
            $bookings->map(fn (SessionBooking $b) => $b->student)->filter()->unique('id'),
        );
        $month = AppClock::currentYearMonth();

        $out = [];
        foreach ($bookings as $booking) {
            $dateKey = $booking->teacher_id.'|'.$this->dateKey($booking->date);
            $siblingKey = $booking->student_id.'|'.($booking->type?->value ?? $booking->type);
            $siblings = $siblingsByStudentType->get($siblingKey, collect());
            $type = $booking->type?->value ?? $booking->type;
            if ($type === SessionBookingType::MasterClass->value) {
                $siblings = $siblings->filter(function (SessionBooking $item) use ($month): bool {
                    $local = $item->starts_at?->timezone(config('app.timezone'));
                    if ($local === null && $item->date !== null) {
                        $local = $item->date->timezone(config('app.timezone'));
                    }
                    if ($local === null) {
                        return false;
                    }

                    return $local->year === $month['year'] && $local->month === $month['month'];
                })->values();
            }
            $out[$booking->id] = $this->buildPayload(
                $booking,
                $viewer,
                $attendances->get($booking->id),
                $issuesByBooking->get($booking->id, collect()),
                $dayMeets->get($dateKey),
                $feedbacks->get($booking->id),
                $siblings,
                $balances[$booking->student_id] ?? null,
            );
        }

        return $out;
    }

    /**
     * @param  \Illuminate\Support\Collection<int, AttendanceIssue>  $issues
     * @param  \Illuminate\Support\Collection<int, SessionBooking>  $siblings
     * @return array<string, mixed>
     */
    /**
     * @param  array{allotment: int, remaining: int}|null  $balance
     */
    private function buildPayload(
        SessionBooking $booking,
        string $viewer,
        ?ClassAttendance $attendance,
        $issues,
        ?TeacherDailyMeeting $dayMeet,
        ?MonthlyFeedback $existingRating,
        $siblings,
        ?array $balance = null,
    ): array {
        $now = AppClock::now();
        $issues = collect($issues);
        $siblings = collect($siblings);
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

        $canStudentJoin = $viewer === 'student' && $booking->status === SessionBookingStatus::Scheduled && $studentJoinOpen;
        $canTeacherJoin = $viewer === 'teacher' && $booking->status !== SessionBookingStatus::Cancelled;
        $canReportTeacher = $viewer === 'student'
            && $this->withinAbsenceReportWindow($ends, $now)
            && ! $issues->contains(
                fn (AttendanceIssue $issue) => $issue->issue_type === AttendanceIssueType::TeacherDidNotJoin,
            );
        $canReportStudent = $this->withinAbsenceReportWindow($ends, $now)
            && ! $studentJoined
            && ! $issues->contains(
                fn (AttendanceIssue $issue) => $issue->issue_type === AttendanceIssueType::StudentDidNotJoin,
            )
            && (
                ($viewer === 'teacher' && $booking->status !== SessionBookingStatus::Cancelled)
                || $viewer === 'student'
            );
        $isMasterClass = $booking->type === SessionBookingType::MasterClass
            || ($booking->type?->value ?? $booking->type) === SessionBookingType::MasterClass->value;
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

        $attempt = $this->attemptFromSiblings($booking, $siblings);
        $isLastChance = $this->isLastChanceFromAttempt($booking, $attempt, $balance);

        return [
            'student_first_join_at' => $attendance?->student_first_join_at?->timezone(config('app.timezone'))->toIso8601String(),
            'student_last_join_at' => $attendance?->student_last_join_at?->timezone(config('app.timezone'))->toIso8601String(),
            'student_join_count' => (int) ($attendance?->student_join_count ?? 0),
            'teacher_booking_join_count' => (int) ($attendance?->teacher_join_count ?? 0),
            'teacher_booking_first_join_at' => $attendance?->teacher_first_join_at?->timezone(config('app.timezone'))->toIso8601String(),
            'teacher_day_join_at' => $dayMeet?->first_join_at?->timezone(config('app.timezone'))->toIso8601String(),
            'teacher_day_join_count' => (int) ($dayMeet?->join_count ?? 0),
            'meeting_url' => $dayMeet?->meet_url,
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
            'is_last_chance' => $isLastChance,
            'last_chance_message' => $isLastChance ? $this->lastChanceMessageForType($booking->type?->value ?? $booking->type) : null,
            'attempt_number' => $attempt,
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
     * @return array<string, mixed>
     */
    private function emptyPayload(): array
    {
        return [
            'student_join_count' => 0,
            'can_join' => false,
            'can_report_teacher_did_not_join' => false,
            'can_report_student_did_not_join' => false,
            'class_completed' => false,
            'report_submitted' => false,
            'rebooking_available' => false,
            'issues' => [],
        ];
    }

    /**
     * @param  \Illuminate\Support\Collection<int, SessionBooking>  $siblings
     */
    private function attemptFromSiblings(SessionBooking $booking, $siblings): int
    {
        $siblings = collect($siblings)->values();
        foreach ($siblings as $index => $item) {
            if ($item->id === $booking->id) {
                return $index + 1;
            }
        }

        return max(1, $siblings->count());
    }

    /**
     * @param  array{allotment: int, remaining: int}|null  $balance
     */
    private function isLastChanceFromAttempt(SessionBooking $booking, int $attempt, ?array $balance = null): bool
    {
        $type = $booking->type?->value ?? $booking->type;
        if ($type === SessionBookingType::IntroductionCall->value) {
            return $attempt >= 2;
        }
        if ($type === SessionBookingType::MasterClass->value) {
            if ($balance === null) {
                $student = $booking->student;
                if ($student === null) {
                    return false;
                }
                $balance = app(MasterClassBalance::class)->snapshot($student);
            }
            if ((int) $balance['allotment'] > 1 || (int) $balance['remaining'] > 0) {
                return false;
            }

            return $attempt >= 2;
        }

        return false;
    }

    /**
     * Read-only balance hints for list payloads (avoids ensure()/writes per row).
     *
     * @param  \Illuminate\Support\Collection<int, \App\Models\StudentProfile>  $students
     * @return array<string, array{allotment: int, remaining: int}>
     */
    private function balanceHintsForStudents($students): array
    {
        $students = collect($students)->filter()->unique(fn ($s) => $s->id)->values();
        if ($students->isEmpty()) {
            return [];
        }

        ['year' => $year, 'month' => $month] = AppClock::currentYearMonth();
        $rows = StudentMasterClassBalance::query()
            ->whereIn('student_id', $students->pluck('id')->all())
            ->where('year', $year)
            ->where('month', $month)
            ->get()
            ->keyBy('student_id');

        $balance = app(MasterClassBalance::class);
        $out = [];
        foreach ($students as $student) {
            $row = $rows->get($student->id);
            if ($row !== null) {
                $out[$student->id] = [
                    'allotment' => (int) $row->allotment,
                    'remaining' => (int) $row->remaining,
                ];

                continue;
            }

            $allotment = $balance->allotmentFor($student);
            $out[$student->id] = [
                'allotment' => $allotment,
                'remaining' => $allotment,
            ];
        }

        return $out;
    }

    private function lastChanceMessageForType(mixed $type): string
    {
        if ($type === SessionBookingType::IntroductionCall->value || $type === SessionBookingType::IntroductionCall) {
            return 'This is your last chance to attend the Introduction Call. If this slot is missed, another interview cannot be booked.';
        }

        return 'This is your last Master Class chance for this month. If this slot is missed, another session cannot be booked until next month.';
    }

    /**
     * @return array<string, int>
     */
    public function dashboardCounts(?int $year = null, ?int $month = null): array
    {
        $bookings = SessionBooking::query()
            ->where('status', '!=', SessionBookingStatus::Cancelled->value)
            ->when($year !== null && $month !== null, fn ($q) => $q->whereYear('date', $year)->whereMonth('date', $month))
            ->selectRaw('count(*) as total_classes')
            ->selectRaw('sum(case when status = ? then 1 else 0 end) as completed_classes', [
                SessionBookingStatus::Completed->value,
            ])
            ->first();

        $issues = AttendanceIssue::query()
            ->when($year !== null && $month !== null, fn ($q) => $q->whereYear('created_at', $year)->whereMonth('created_at', $month))
            ->selectRaw('sum(case when verification_status = ? then 1 else 0 end) as pending_verification', [
                AttendanceVerificationStatus::Pending->value,
            ])
            ->selectRaw("sum(case when reporter_role = 'student' then 1 else 0 end) as student_attendance_reports")
            ->selectRaw("sum(case when reporter_role = 'teacher' then 1 else 0 end) as teacher_attendance_reports")
            ->selectRaw('sum(case when admin_decision = ? then 1 else 0 end) as verified_teacher_absence', [
                AttendanceDecision::TeacherAbsent->value,
            ])
            ->selectRaw('sum(case when admin_decision = ? then 1 else 0 end) as verified_student_absence', [
                AttendanceDecision::StudentAbsent->value,
            ])
            ->selectRaw('sum(case when admin_decision = ? then 1 else 0 end) as technical_issues', [
                AttendanceDecision::TechnicalIssue->value,
            ])
            ->first();

        $rebookings = ClassAttendance::query()
            ->where('rebooking_granted', true)
            ->when($year !== null && $month !== null, fn ($q) => $q->whereYear('rebooking_granted_at', $year)->whereMonth('rebooking_granted_at', $month))
            ->count();

        return [
            'total_classes' => (int) ($bookings->total_classes ?? 0),
            'completed_classes' => (int) ($bookings->completed_classes ?? 0),
            'pending_verification' => (int) ($issues->pending_verification ?? 0),
            'student_attendance_reports' => (int) ($issues->student_attendance_reports ?? 0),
            'teacher_attendance_reports' => (int) ($issues->teacher_attendance_reports ?? 0),
            'verified_teacher_absence' => (int) ($issues->verified_teacher_absence ?? 0),
            'verified_student_absence' => (int) ($issues->verified_student_absence ?? 0),
            'technical_issues' => (int) ($issues->technical_issues ?? 0),
            'rebookings_given' => $rebookings,
        ];
    }

    /**
     * @return array<string, mixed>
     */
    public function issueDetail(AttendanceIssue $issue): array
    {
        return $this->issueDetails(collect([$issue]))->first()
            ?? [];
    }

    /**
     * Batch attendance issue details for admin list (avoids N+1 per issue).
     *
     * @param  \Illuminate\Support\Collection<int, AttendanceIssue>  $issues
     * @return \Illuminate\Support\Collection<int, array<string, mixed>>
     */
    public function issueDetails($issues)
    {
        $issues = collect($issues)->filter(fn ($i) => $i instanceof AttendanceIssue)->values();
        if ($issues->isEmpty()) {
            return collect();
        }

        $issues = $issues instanceof \Illuminate\Database\Eloquent\Collection
            ? $issues
            : new \Illuminate\Database\Eloquent\Collection($issues->all());

        $issues->loadMissing([
            'booking.student.academicLevel',
            'booking.student.activeEnrollment.batch.level',
            'booking.student.currentLevelJourney',
            'booking.student.levelJourneys',
            'booking.teacher',
            'reporter',
            'verifier',
        ]);

        $bookingIds = $issues->pluck('booking_id')->filter()->unique()->values()->all();
        $attendances = ClassAttendance::query()
            ->whereIn('booking_id', $bookingIds)
            ->get()
            ->keyBy('booking_id');

        $bookings = $issues->map(fn (AttendanceIssue $i) => $i->booking)->filter();
        $teacherIds = $bookings->pluck('teacher_id')->filter()->unique()->values()->all();
        $dates = $bookings->map(fn (SessionBooking $b) => $this->dateKey($b->date))->filter()->unique()->values()->all();
        $dayMeets = $this->dayMeetsKeyedByTeacherDate($teacherIds, $dates);

        $siblingsByBooking = AttendanceIssue::query()
            ->whereIn('booking_id', $bookingIds)
            ->orderBy('created_at')
            ->get()
            ->groupBy('booking_id');

        $studentIds = $bookings->pluck('student_id')->filter()->unique()->values()->all();
        $attemptSiblings = SessionBooking::query()
            ->whereIn('student_id', $studentIds)
            ->where('status', '!=', SessionBookingStatus::Cancelled->value)
            ->orderBy('starts_at')
            ->get(['id', 'student_id', 'type', 'starts_at', 'date', 'status'])
            ->groupBy(fn (SessionBooking $b) => $b->student_id.'|'.($b->type?->value ?? $b->type));
        $month = AppClock::currentYearMonth();

        return $issues->map(function (AttendanceIssue $issue) use (
            $attendances,
            $dayMeets,
            $siblingsByBooking,
            $attemptSiblings,
            $month,
        ): array {
            $booking = $issue->booking;
            $attendance = $booking ? $attendances->get($booking->id) : null;
            $dayMeet = $booking
                ? $dayMeets->get($booking->teacher_id.'|'.$this->dateKey($booking->date))
                : null;
            $sibling = $siblingsByBooking->get($issue->booking_id, collect());
            $type = $booking?->type?->value ?? $booking?->type;
            $student = $booking?->student;
            $levelName = $student?->academicLevel?->name
                ?? $student?->activeEnrollment?->batch?->level?->name;

            $attempt = null;
            $learningWeek = null;
            if ($booking !== null) {
                $siblingKey = $booking->student_id.'|'.$type;
                $siblings = $attemptSiblings->get($siblingKey, collect());
                if ($type === SessionBookingType::MasterClass->value) {
                    $siblings = $siblings->filter(function (SessionBooking $item) use ($month): bool {
                        $local = $item->starts_at?->timezone(config('app.timezone'));
                        if ($local === null && $item->date !== null) {
                            $local = $item->date->timezone(config('app.timezone'));
                        }
                        if ($local === null) {
                            return false;
                        }

                        return $local->year === $month['year'] && $local->month === $month['month'];
                    })->values();
                }
                $attempt = $this->attemptFromSiblings($booking, $siblings);
                if ($type === 'master_class' || $type === SessionBookingType::MasterClass->value) {
                    $learningWeek = $this->learningWeekFromLoaded($booking);
                }
            }

            return [
                'id' => $issue->id,
                'student_name' => $booking?->student?->full_name,
                'teacher_name' => $booking?->teacher?->full_name,
                'student_id' => $booking?->student_id,
                'teacher_id' => $booking?->teacher_id,
                'booking_id' => $issue->booking_id,
                'booking_type' => $type,
                'attempt_number' => $attempt,
                'learning_week' => $learningWeek,
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
        })->values();
    }

    private function learningWeekFromLoaded(SessionBooking $booking): ?int
    {
        $student = $booking->student;
        $at = $booking->starts_at;
        if ($student === null || $at === null) {
            return null;
        }

        $journey = $student->currentLevelJourney;
        if ($journey === null || ($journey->started_at !== null && $journey->started_at->gt($at))) {
            $journeys = $student->relationLoaded('levelJourneys')
                ? $student->levelJourneys
                : collect();
            $journey = $journeys->first(function ($row) use ($at): bool {
                if ($row->started_at !== null && $row->started_at->gt($at)) {
                    return false;
                }

                return $row->ended_at === null || $row->ended_at->gte($at);
            });
        }

        return $journey?->weekNumberAt($at);
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
            ->whereDate('date', $this->dateKey($booking->date))
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

    /**
     * Batch-load teacher day meets. Prefer whereDate over whereIn('date'): the column
     * is often stored as midnight datetime ("Y-m-d 00:00:00"), which whereIn with
     * date-only strings fails to match on PostgreSQL.
     *
     * @param  list<string>  $teacherIds
     * @param  list<string>  $dates  Y-m-d strings
     * @return \Illuminate\Support\Collection<string, TeacherDailyMeeting>
     */
    private function dayMeetsKeyedByTeacherDate(array $teacherIds, array $dates)
    {
        if ($teacherIds === [] || $dates === []) {
            return collect();
        }

        return TeacherDailyMeeting::query()
            ->whereIn('teacher_id', $teacherIds)
            ->where(function ($query) use ($dates): void {
                foreach ($dates as $date) {
                    $query->orWhereDate('date', $date);
                }
            })
            ->get()
            ->keyBy(fn (TeacherDailyMeeting $m) => $m->teacher_id.'|'.$this->dateKey($m->date));
    }

    private function dateKey(mixed $date): ?string
    {
        if ($date === null || $date === '') {
            return null;
        }

        return Carbon::parse($date)->toDateString();
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

    private function notifyAdminsOfReport(
        AttendanceIssue $issue,
        User $reporter,
        AttendanceIssueType $type,
    ): void {
        try {
            $issue->loadMissing(['booking.student', 'booking.teacher']);
            $booking = $issue->booking;
            $date = $booking?->date?->toDateString();
            $displayDate = AppClock::formatDisplayDate($date, 'a class');
            $studentName = $booking?->student?->full_name ?? 'student';
            $teacherName = $booking?->teacher?->full_name ?? 'teacher';
            $reporterName = $reporter->name ?: 'Someone';
            $issueLabel = match ($type) {
                AttendanceIssueType::TeacherDidNotJoin => 'teacher did not join',
                AttendanceIssueType::StudentDidNotJoin => 'student did not join',
            };

            $this->notifyAdmins->execute(
                NotificationType::AttendanceConflictReported,
                'Class conflict reported',
                "{$reporterName} reported {$issueLabel} for {$studentName} / {$teacherName} on {$displayDate}.",
                [
                    'issue_id' => $issue->id,
                    'booking_id' => $issue->booking_id,
                    'issue_type' => $type->value,
                    'reporter_role' => $issue->reporter_role,
                    'link' => '/admin/attendance/'.$issue->id,
                ],
            );
        } catch (Throwable) {
            // Report must succeed even if notify fails.
        }
    }

    private function notifyReporterOfResolution(
        AttendanceIssue $issue,
        AttendanceDecision $decision,
    ): void {
        try {
            $issue->loadMissing(['reporter', 'booking']);
            $reporter = $issue->reporter;
            if ($reporter === null) {
                return;
            }

            $date = $issue->booking?->date?->toDateString();
            $displayDate = AppClock::formatDisplayDate($date, 'your class');
            $decisionLabel = str_replace('_', ' ', $decision->value);

            $this->notifications->safeExecute(
                $reporter,
                NotificationType::AttendanceConflictResolved,
                'Class conflict reviewed',
                "Your attendance report for {$displayDate} was reviewed ({$decisionLabel}).",
                [
                    'issue_id' => $issue->id,
                    'booking_id' => $issue->booking_id,
                    'decision' => $decision->value,
                    'link' => $issue->reporter_role === 'student'
                        ? '/student/bookings'
                        : '/teacher/schedule/day',
                ],
            );
        } catch (Throwable) {
            // Resolve must succeed even if notify fails.
        }
    }
}