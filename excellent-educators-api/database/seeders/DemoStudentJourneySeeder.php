<?php

namespace Database\Seeders;

use App\Actions\Assessments\SubmitStudentAssessment;
use App\Actions\Batches\ActivateBatch;
use App\Actions\Learning\StartStudentLevelJourney;
use App\Actions\Mentoring\AssignMasterTeacher;
use App\Actions\Students\CreateStudent;
use App\Enums\AttendanceDecision;
use App\Enums\AttendanceIssueType;
use App\Enums\AttendanceVerificationStatus;
use App\Enums\FeedbackTargetType;
use App\Enums\PaymentMode;
use App\Enums\ProfileStatus;
use App\Enums\RoleName;
use App\Enums\SessionBookingStatus;
use App\Enums\SessionBookingType;
use App\Models\AcademicLevel;
use App\Models\AptitudeAssessment;
use App\Models\AttendanceIssue;
use App\Models\Batch;
use App\Models\BatchStudent;
use App\Models\ClassAttendance;
use App\Models\Dimension;
use App\Models\MasterTeacherAssignment;
use App\Models\MonthlyFeedback;
use App\Models\MonthlyFeedbackItem;
use App\Models\SessionBooking;
use App\Models\StudentLevelJourney;
use App\Models\StudentMasterClassBalance;
use App\Models\StudentPaymentPlan;
use App\Models\StudentProfile;
use App\Models\TeacherProfile;
use App\Models\User;
use App\Models\WeeklyAssignmentAttempt;
use App\Models\WeeklyLearning;
use App\Payments\PaymentPlanService;
use App\Scheduling\MasterClassBalance;
use App\Scheduling\SlotGrid;
use Database\Seeders\Support\DemoSeedData;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

/**
 * Seeds multiple backdated demo students covering common test cases.
 *
 * Static payloads live in DemoSeedData::studentJourneys().
 */
class DemoStudentJourneySeeder extends Seeder
{
    public function run(): void
    {
        $level = AcademicLevel::query()->where('name', 'Level 1')->first();
        if ($level === null) {
            $this->command?->warn('Level 1 missing — run LevelSeeder first.');

            return;
        }

        $assessment = AptitudeAssessment::query()->where('status', 'active')->orderBy('created_at')->first();
        if ($assessment === null) {
            $this->command?->warn('No active aptitude assessment — aptitude steps will be skipped.');
        }

        $admin = User::query()->where('email', 'admin1@excellenteducators.test')->first()
            ?? User::query()->role(RoleName::SuperAdmin->value)->first();
        if ($admin === null) {
            $this->command?->warn('No admin user to act as creator.');

            return;
        }

        Auth::login($admin);

        $seeded = 0;
        foreach (DemoSeedData::studentJourneys() as $data) {
            if ($this->seedOne($data, $level, $assessment, $admin)) {
                $seeded++;
            }
        }

        Auth::logout();

        $this->command?->info("Seeded {$seeded} demo journey student(s). Password: ".DemoSeedData::STUDENT_PASSWORD);
        $this->command?->info('Primary login: student1@yopmail.com');
    }

    /**
     * @param  array<string, mixed>  $data
     */
    private function seedOne(
        array $data,
        AcademicLevel $level,
        ?AptitudeAssessment $assessment,
        User $admin,
    ): bool {
        $email = $data['student']['email'];
        $label = $data['label'] ?? ($data['key'] ?? $email);

        if (User::query()->where('email', $email)->exists()) {
            $this->command?->info("Demo student {$email} already exists — skipping ({$label}).");

            return false;
        }

        $teacher = TeacherProfile::query()
            ->whereHas('user', fn ($q) => $q->where('email', $data['master_teacher_email']))
            ->first();
        if ($teacher === null) {
            $this->command?->warn("Master teacher {$data['master_teacher_email']} missing — skip {$email}.");

            return false;
        }

        $createdAt = Carbon::parse($data['student']['created_at'], config('app.timezone'));
        $journeyStartedAt = Carbon::parse($data['journey_started_at'], config('app.timezone'));

        DB::transaction(function () use (
            $data,
            $level,
            $teacher,
            $assessment,
            $admin,
            $createdAt,
            $journeyStartedAt,
        ): void {
            $this->ensureActiveBatch($level, $journeyStartedAt);

            $studentInput = $data['student'];
            $paymentInput = $data['payment'];
            unset($studentInput['created_at']);

            $student = app(CreateStudent::class)->execute([
                ...$studentInput,
                'level_id' => $level->id,
                'payment' => [
                    'payment_type' => $paymentInput['payment_type'],
                    'total_amount' => $paymentInput['total_amount'],
                    'initial_amount' => $paymentInput['initial_amount'],
                    'due_day' => $paymentInput['due_day'],
                    'preferred_mode' => $paymentInput['preferred_mode'],
                    'start_date' => $paymentInput['start_date'],
                    'payment_date' => $paymentInput['payment_date'],
                    'notes' => $paymentInput['notes'],
                ],
            ]);

            $student->load('activeEnrollment.batch');
            $batch = $student->activeEnrollment?->batch;
            if ($batch !== null) {
                app(ActivateBatch::class)->execute($batch);
                $batch->update(['starts_on' => $journeyStartedAt->toDateString()]);
            }

            app(StartStudentLevelJourney::class)
                ->execute($student->fresh(), $level, $journeyStartedAt);

            $this->backdateStudent($student->fresh(), $createdAt, $journeyStartedAt);

            $assignment = app(AssignMasterTeacher::class)->execute($student->fresh(), $teacher, $admin);
            $assignedAt = Carbon::parse($data['master_teacher_assigned_at'], config('app.timezone'));
            MasterTeacherAssignment::query()->whereKey($assignment->id)->update([
                'started_at' => $assignedAt,
                'created_at' => $assignedAt,
            ]);

            $skipAptitude = (bool) ($data['skip_aptitude'] ?? false);
            if (! $skipAptitude && $assessment !== null && ! empty($data['aptitude_submitted_at'])) {
                $this->seedAptitude($student->fresh(), $assessment, $data);
            }

            $this->seedWeeklyAttempts($student->fresh(), $level, $data['weekly_attempts'] ?? []);
            $this->seedBookingsAndFeedback($student->fresh(), $teacher, $admin, $data['bookings'] ?? []);
            $this->seedFollowUpPayments($student->fresh(), $paymentInput['follow_up_payments'] ?? [], $admin->id);
            $this->seedMasterClassBalances($student->fresh(), $data['bookings'] ?? []);
        });

        $this->command?->info("Seeded {$email} — {$label}");

        return true;
    }

    private function ensureActiveBatch(AcademicLevel $level, Carbon $journeyStartedAt): void
    {
        $batch = Batch::query()
            ->where('level_id', $level->id)
            ->where('name', 'Batch 1')
            ->first();

        if ($batch === null) {
            Batch::query()->create([
                'level_id' => $level->id,
                'name' => 'Batch 1',
                'academic_year' => (int) $journeyStartedAt->format('Y'),
                'year' => (int) $journeyStartedAt->format('Y'),
                'month' => (int) $journeyStartedAt->format('n'),
                'enrolled_watermark' => 0,
                'starts_on' => $journeyStartedAt->toDateString(),
                'status' => 'active',
            ]);
        } else {
            $batch->update([
                'status' => 'active',
                'starts_on' => $journeyStartedAt->toDateString(),
            ]);
        }
    }

    private function backdateStudent(StudentProfile $student, Carbon $createdAt, Carbon $journeyStartedAt): void
    {
        User::query()->whereKey($student->user_id)->update([
            'created_at' => $createdAt,
            'updated_at' => $createdAt,
            'email_verified_at' => $createdAt,
        ]);

        StudentProfile::query()->whereKey($student->id)->update([
            'created_at' => $createdAt,
            'updated_at' => $createdAt,
        ]);

        BatchStudent::query()
            ->where('student_id', $student->id)
            ->whereNull('left_at')
            ->update([
                'enrolled_at' => $createdAt,
                'created_at' => $createdAt,
                'updated_at' => $createdAt,
                'status' => ProfileStatus::Active->value,
            ]);

        StudentLevelJourney::query()
            ->where('student_id', $student->id)
            ->whereNull('ended_at')
            ->update([
                'started_at' => $journeyStartedAt,
                'created_at' => $journeyStartedAt,
                'updated_at' => $journeyStartedAt,
            ]);
    }

    /**
     * @param  array<string, mixed>  $data
     */
    private function seedAptitude(StudentProfile $student, AptitudeAssessment $assessment, array $data): void
    {
        $assessment->load(['questions.options']);
        $optionIndex = (int) ($data['aptitude_option_index'] ?? 0);
        $answers = [];
        foreach ($assessment->questions as $question) {
            $option = $question->options->sortBy('display_order')->values()->get($optionIndex)
                ?? $question->options->first();
            if ($option === null) {
                continue;
            }
            $answers[] = [
                'question_id' => $question->id,
                'option_id' => $option->id,
            ];
        }

        if ($answers === []) {
            return;
        }

        $result = app(SubmitStudentAssessment::class)->execute($student, $assessment, $answers);
        $at = Carbon::parse($data['aptitude_submitted_at'], config('app.timezone'));
        $attemptId = $result->aptitude_assessment_attempt_id;
        DB::table('aptitude_assessment_attempts')->where('id', $attemptId)->update([
            'started_at' => $at->copy()->subMinutes(25),
            'submitted_at' => $at,
            'created_at' => $at,
            'updated_at' => $at,
        ]);
        DB::table('aptitude_assessment_results')->where('id', $result->id)->update([
            'calculated_at' => $at,
            'created_at' => $at,
            'updated_at' => $at,
        ]);
    }

    /**
     * @param  list<array{week_number: int, submitted_at: string, option_index: int}>  $attempts
     */
    private function seedWeeklyAttempts(StudentProfile $student, AcademicLevel $level, array $attempts): void
    {
        $journey = StudentLevelJourney::query()
            ->where('student_id', $student->id)
            ->whereNull('ended_at')
            ->first();
        if ($journey === null) {
            return;
        }

        foreach ($attempts as $row) {
            $learning = WeeklyLearning::query()
                ->where('level_id', $level->id)
                ->where('week_number', $row['week_number'])
                ->with(['questions.options'])
                ->first();
            if ($learning === null) {
                continue;
            }

            $optionIndex = (int) $row['option_index'];
            $answers = [];
            foreach ($learning->questions as $question) {
                $option = $question->options->sortBy('display_order')->values()->get($optionIndex)
                    ?? $question->options->first();
                if ($option === null) {
                    continue;
                }
                $answers[] = [
                    'question_id' => $question->id,
                    'option_id' => $option->id,
                ];
            }

            $submittedAt = Carbon::parse($row['submitted_at'], config('app.timezone'));
            WeeklyAssignmentAttempt::query()->create([
                'student_id' => $student->id,
                'student_level_journey_id' => $journey->id,
                'weekly_learning_id' => $learning->id,
                'week_number' => $row['week_number'],
                'attempt_number' => 1,
                'answers' => $answers,
                'video_url' => $learning->video_url,
                'submitted_at' => $submittedAt,
                'created_at' => $submittedAt,
                'updated_at' => $submittedAt,
            ]);
        }
    }

    /**
     * @param  list<array<string, mixed>>  $bookings
     */
    private function seedBookingsAndFeedback(
        StudentProfile $student,
        TeacherProfile $teacher,
        User $admin,
        array $bookings,
    ): void {
        $dimensions = Dimension::query()->orderBy('code')->get();
        $teacherUserId = $teacher->user_id;

        foreach ($bookings as $row) {
            $startsAt = Carbon::parse(SlotGrid::atDate($row['date'], $row['start']));
            $endsAt = $startsAt->copy()->addMinutes(30);
            $type = $row['type'] === 'introduction_call'
                ? SessionBookingType::IntroductionCall
                : SessionBookingType::MasterClass;
            $status = match ($row['status'] ?? 'completed') {
                'cancelled' => SessionBookingStatus::Cancelled,
                'scheduled' => SessionBookingStatus::Scheduled,
                default => SessionBookingStatus::Completed,
            };
            $attendanceMode = $row['attendance'] ?? (
                $status === SessionBookingStatus::Completed ? 'attended' : 'none'
            );

            $booking = SessionBooking::query()->create([
                'student_id' => $student->id,
                'teacher_id' => $teacher->id,
                'type' => $type,
                'date' => $row['date'],
                'starts_at' => $startsAt,
                'ends_at' => $endsAt,
                'status' => $status,
            ]);
            SessionBooking::query()->whereKey($booking->id)->update([
                'created_at' => $startsAt->copy()->subDays(2),
                'updated_at' => $endsAt,
            ]);

            if ($attendanceMode !== 'none') {
                $this->seedAttendance($booking, $student, $teacher, $startsAt, $endsAt, $attendanceMode, $row, $admin, $teacherUserId);
            }

            if (! ($row['rate'] ?? false) || empty($row['feedback']) || $attendanceMode !== 'attended') {
                continue;
            }

            $feedbackMeta = $row['feedback'];
            $sessionDate = Carbon::parse($row['date'], config('app.timezone'));
            $feedback = MonthlyFeedback::query()->create([
                'student_id' => $student->id,
                'master_teacher_id' => $teacher->id,
                'session_booking_id' => $booking->id,
                'year' => (int) $sessionDate->format('Y'),
                'month' => (int) $sessionDate->format('n'),
                'session_date' => $row['date'],
                'positive_points' => $feedbackMeta['positive_points'],
                'areas_for_improvement' => $feedbackMeta['areas_for_improvement'],
                'discussed_in_class' => $feedbackMeta['discussed_in_class'],
                'submitted_at' => $endsAt->copy()->addHours(2),
            ]);

            $rating = (int) ($feedbackMeta['dimension_rating'] ?? 7);
            foreach ($dimensions as $dimension) {
                MonthlyFeedbackItem::query()->create([
                    'monthly_feedback_id' => $feedback->id,
                    'target_type' => FeedbackTargetType::Dimension,
                    'target_id' => $dimension->id,
                    'rating' => $rating,
                ]);
            }
        }
    }

    /**
     * @param  array<string, mixed>  $row
     */
    private function seedAttendance(
        SessionBooking $booking,
        StudentProfile $student,
        TeacherProfile $teacher,
        Carbon $startsAt,
        Carbon $endsAt,
        string $attendanceMode,
        array $row,
        User $admin,
        string $teacherUserId,
    ): void {
        $studentJoined = $attendanceMode === 'attended';
        $teacherJoined = in_array($attendanceMode, ['attended', 'student_missed'], true);

        $attendance = ClassAttendance::query()->create([
            'booking_id' => $booking->id,
            'student_id' => $student->id,
            'teacher_id' => $teacher->id,
            'student_first_join_at' => $studentJoined ? $startsAt->copy()->addMinutes(1) : null,
            'student_last_join_at' => $studentJoined ? $endsAt->copy()->subMinutes(2) : null,
            'student_join_count' => $studentJoined ? 1 : 0,
            'teacher_first_join_at' => $teacherJoined ? $startsAt : null,
            'teacher_last_join_at' => $teacherJoined ? $endsAt : null,
            'teacher_join_count' => $teacherJoined ? 1 : 0,
            'rebooking_granted' => (bool) ($row['rebooking_granted'] ?? false),
            'rebooking_granted_at' => ($row['rebooking_granted'] ?? false) ? $endsAt->copy()->addHour() : null,
            'created_at' => $startsAt,
            'updated_at' => $endsAt,
        ]);

        $issueMeta = $row['attendance_issue'] ?? null;
        if (! is_array($issueMeta)) {
            return;
        }

        $issueType = AttendanceIssueType::from($issueMeta['issue_type']);
        $decision = AttendanceDecision::from($issueMeta['decision']);
        $resolvedAt = $endsAt->copy()->addHours(2);

        AttendanceIssue::query()->create([
            'booking_id' => $booking->id,
            'reporter_user_id' => $teacherUserId,
            'reporter_role' => RoleName::MasterTeacher->value,
            'issue_type' => $issueType->value,
            'message' => $issueMeta['message'] ?? 'Demo attendance issue',
            'verification_status' => AttendanceVerificationStatus::Resolved->value,
            'admin_decision' => $decision->value,
            'admin_notes' => 'Seeded demo resolution',
            'verified_by' => $admin->id,
            'verified_at' => $resolvedAt,
            'created_at' => $endsAt->copy()->addMinutes(30),
            'updated_at' => $resolvedAt,
        ]);

        // Ensure rebooking flag is set when decision grants a chance.
        if (! $attendance->rebooking_granted && in_array($decision, [
            AttendanceDecision::TeacherAbsent,
            AttendanceDecision::TechnicalIssue,
            AttendanceDecision::StudentAbsent,
            AttendanceDecision::BothAbsent,
            AttendanceDecision::ExtraChance,
        ], true)) {
            $attendance->update([
                'rebooking_granted' => true,
                'rebooking_granted_at' => $resolvedAt,
            ]);
        }
    }

    /**
     * @param  list<array{amount: float|int, payment_date: string, notes?: string}>  $payments
     */
    private function seedFollowUpPayments(StudentProfile $student, array $payments, string $adminId): void
    {
        $plan = StudentPaymentPlan::query()
            ->where('student_id', $student->id)
            ->where('is_active', true)
            ->first();
        if ($plan === null || $payments === []) {
            return;
        }

        $service = app(PaymentPlanService::class);
        foreach ($payments as $payment) {
            $service->recordSuccessfulPayment($plan->fresh(), [
                'amount' => $payment['amount'],
                'payment_mode' => PaymentMode::Offline->value,
                'payment_date' => $payment['payment_date'],
                'notes' => $payment['notes'] ?? 'Demo installment',
            ], $adminId);
        }
    }

    /**
     * @param  list<array<string, mixed>>  $bookings
     */
    private function seedMasterClassBalances(StudentProfile $student, array $bookings): void
    {
        $byMonth = [];
        foreach ($bookings as $row) {
            if (($row['type'] ?? '') !== 'master_class') {
                continue;
            }
            // Only completed/attended MCs consume balance; missed ones that restore
            // credit should not leave remaining at 0 for the month.
            if (($row['attendance'] ?? 'attended') === 'student_missed') {
                continue;
            }
            $date = Carbon::parse($row['date'], config('app.timezone'));
            $key = $date->format('Y-n');
            $byMonth[$key] = ($byMonth[$key] ?? 0) + 1;
        }

        $allotment = app(MasterClassBalance::class)->allotmentFor($student);
        foreach ($byMonth as $key => $used) {
            [$year, $month] = array_map('intval', explode('-', $key));
            StudentMasterClassBalance::query()->updateOrCreate(
                [
                    'student_id' => $student->id,
                    'year' => $year,
                    'month' => $month,
                ],
                [
                    'allotment' => $allotment,
                    'remaining' => max(0, $allotment - $used),
                ],
            );
        }

        app(MasterClassBalance::class)->ensure($student->fresh());
    }
}
