<?php

namespace Tests\Feature\Api\V1;

use App\Attendance\AttendanceService;
use App\Enums\AttendanceDecision;
use App\Enums\SessionBookingStatus;
use App\Meetings\FakeGoogleMeetGateway;
use App\Meetings\GoogleMeetGateway;
use App\Models\AttendanceIssue;
use App\Models\ClassAttendance;
use App\Models\ClassJoinEvent;
use App\Models\MonthlyFeedback;
use App\Models\SessionBooking;
use App\Models\StudentProfile;
use App\Models\TeacherProfile;
use Database\Seeders\CareerCompassLevelSeeder;
use Database\Seeders\LevelSeeder;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Tests\TestCase;

class ClassAttendanceTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed([RoleSeeder::class, CareerCompassLevelSeeder::class, LevelSeeder::class]);
        Carbon::setTestNow(Carbon::parse('2026-09-16 09:50:00', 'Asia/Kolkata'));
        $this->app->instance(GoogleMeetGateway::class, new FakeGoogleMeetGateway);
    }

    public function test_student_cannot_join_until_two_minutes_before_start(): void
    {
        [$student, $teacher] = $this->makeStudentWithTeacher();
        $booking = $this->book($student, $teacher, '10:00');

        $this->withToken($this->tokenFor($student->user))
            ->postJson('/api/v1/student/bookings/'.$booking->id.'/join')
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'JOIN_TOO_EARLY');

        Carbon::setTestNow(Carbon::parse('2026-09-16 09:58:00', 'Asia/Kolkata'));
        $this->withToken($this->tokenFor($student->user))
            ->postJson('/api/v1/student/bookings/'.$booking->id.'/join')
            ->assertOk()
            ->assertJsonPath('data.attendance.student_join_count', 1);

        $this->withToken($this->tokenFor($student->user))
            ->postJson('/api/v1/student/bookings/'.$booking->id.'/join')
            ->assertOk()
            ->assertJsonPath('data.attendance.student_join_count', 2);

        $this->assertSame(2, ClassJoinEvent::query()->count());
        $this->assertSame(1, ClassAttendance::query()->count());
    }

    public function test_teacher_can_join_anytime_and_missing_click_is_not_absence(): void
    {
        [$student, $teacher] = $this->makeStudentWithTeacher();
        $first = $this->book($student, $teacher, '10:00');
        $secondStudent = $this->makeSecondStudent();
        $second = $this->book($secondStudent, $teacher, '10:30');

        $this->withToken($this->tokenFor($teacher->user))
            ->postJson('/api/v1/teacher/schedule/bookings/'.$first->id.'/join')
            ->assertOk();

        $payload = $this->withToken($this->tokenFor($teacher->user))
            ->getJson('/api/v1/teacher/schedule/day?date=2026-09-16')
            ->assertOk()
            ->json('data.bookings');

        $byId = collect($payload)->keyBy('id');
        $this->assertSame(1, $byId[$first->id]['attendance']['teacher_booking_join_count']);
        $this->assertSame(0, $byId[$second->id]['attendance']['teacher_booking_join_count']);
        $this->assertNotNull($byId[$second->id]['attendance']['teacher_day_join_at']);
        $this->assertFalse($byId[$second->id]['attendance']['can_report_student_did_not_join']);
        $this->assertDatabaseMissing('attendance_issues', ['booking_id' => $second->id]);
    }

    public function test_student_and_teacher_reports_go_to_admin_with_message(): void
    {
        [$student, $teacher] = $this->makeStudentWithTeacher();
        $booking = $this->book($student, $teacher, '10:00');
        Carbon::setTestNow(Carbon::parse('2026-09-16 09:58:00', 'Asia/Kolkata'));
        $this->withToken($this->tokenFor($student->user))->postJson('/api/v1/student/bookings/'.$booking->id.'/join')->assertOk();
        Carbon::setTestNow(Carbon::parse('2026-09-16 10:31:00', 'Asia/Kolkata'));

        $this->withToken($this->tokenFor($student->user))->postJson(
            '/api/v1/student/bookings/'.$booking->id.'/attendance-reports',
            ['message' => 'Teacher did not join. I waited for 10 minutes.'],
        )->assertCreated()->assertJsonPath('message', 'Report sent to Admin.');

        $this->assertDatabaseHas('attendance_issues', [
            'booking_id' => $booking->id,
            'issue_type' => 'teacher_did_not_join',
            'message' => 'Teacher did not join. I waited for 10 minutes.',
        ]);

        $other = $this->book($this->makeSecondStudent(), $teacher, '11:00');
        Carbon::setTestNow(Carbon::parse('2026-09-16 11:31:00', 'Asia/Kolkata'));
        $this->withToken($this->tokenFor($teacher->user))->postJson(
            '/api/v1/teacher/schedule/bookings/'.$other->id.'/attendance-reports',
            ['message' => 'Student did not attend the scheduled class.'],
        )->assertCreated();

        $outsider = $this->makeSecondStudent();
        $this->withToken($this->tokenFor($outsider->user))
            ->postJson('/api/v1/student/bookings/'.$booking->id.'/attendance-reports', ['message' => 'Not my class.'])
            ->assertNotFound();
    }

    public function test_teacher_did_not_join_report_closes_one_hour_after_class_ends(): void
    {
        [$student, $teacher] = $this->makeStudentWithTeacher();
        $booking = $this->book($student, $teacher, '10:00');
        $token = $this->tokenFor($student->user);

        Carbon::setTestNow(Carbon::parse('2026-09-16 10:31:00', 'Asia/Kolkata'));
        $this->withToken($token)->getJson('/api/v1/student/bookings')
            ->assertOk()
            ->assertJsonPath('data.0.attendance.can_report_teacher_did_not_join', true);

        Carbon::setTestNow(Carbon::parse('2026-09-16 11:30:00', 'Asia/Kolkata'));
        $this->withToken($token)->getJson('/api/v1/student/bookings')
            ->assertOk()
            ->assertJsonPath('data.0.attendance.can_report_teacher_did_not_join', true);

        Carbon::setTestNow(Carbon::parse('2026-09-16 11:31:00', 'Asia/Kolkata'));
        $this->withToken($token)->getJson('/api/v1/student/bookings')
            ->assertOk()
            ->assertJsonPath('data.0.attendance.can_report_teacher_did_not_join', false);

        $this->withToken($token)->postJson(
            '/api/v1/student/bookings/'.$booking->id.'/attendance-reports',
            ['message' => 'Teacher did not join the Meet.'],
        )
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'ATTENDANCE_REPORT_TOO_LATE');
    }

    public function test_admin_can_verify_teacher_absent_and_student_gets_one_rebooking(): void
    {
        [$student, $teacher] = $this->makeStudentWithTeacher();
        Carbon::setTestNow(Carbon::parse('2026-09-16 08:00:00', 'Asia/Kolkata'));
        $intro = $this->book($student, $teacher, '10:00');
        $intro->update(['status' => SessionBookingStatus::Completed->value]);
        \App\Models\StudentLevelJourney::query()
            ->where('student_id', $student->id)
            ->whereNull('ended_at')
            ->update(['started_at' => Carbon::parse('2026-08-01 00:00:00', 'Asia/Kolkata')]);
        $booking = $this->withToken($this->tokenFor($student->user))->postJson('/api/v1/student/bookings', [
            'teacher_id' => $teacher->id,
            'type' => 'master_class',
            'date' => '2026-09-16',
            'start' => '11:00',
        ])->assertCreated();
        $bookingId = $booking->json('data.id');

        Carbon::setTestNow(Carbon::parse('2026-09-16 10:58:00', 'Asia/Kolkata'));
        $this->withToken($this->tokenFor($student->user))->postJson('/api/v1/student/bookings/'.$bookingId.'/join')->assertOk();
        Carbon::setTestNow(Carbon::parse('2026-09-16 11:31:00', 'Asia/Kolkata'));
        $this->withToken($this->tokenFor($student->user))->postJson(
            '/api/v1/student/bookings/'.$bookingId.'/attendance-reports',
            ['message' => 'Teacher did not join the Meet.'],
        )->assertCreated();

        $issue = AttendanceIssue::query()->first();
        $admin = $this->makeAdmin();
        $this->withToken($this->tokenFor($student->user))
            ->postJson('/api/v1/admin/attendance/'.$issue->id.'/resolve', ['decision' => 'teacher_absent'])
            ->assertForbidden();

        $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/attendance/'.$issue->id.'/resolve', [
            'decision' => AttendanceDecision::ExtraChance->value,
        ])->assertOk()->assertJsonPath('data.admin_decision', 'extra_chance');

        SessionBooking::query()->whereKey($bookingId)->update(['status' => SessionBookingStatus::Completed->value]);

        Carbon::setTestNow(Carbon::parse('2026-09-20 08:00:00', 'Asia/Kolkata'));
        $this->withToken($this->tokenFor($student->user))->postJson('/api/v1/student/bookings', [
            'teacher_id' => $teacher->id,
            'type' => 'master_class',
            'date' => '2026-09-22',
            'start' => '11:00',
        ])->assertCreated();

        $this->assertNotNull(ClassAttendance::query()->where('booking_id', $bookingId)->first()->replacement_booking_id);

        $this->withToken($this->tokenFor($student->user))->postJson('/api/v1/student/bookings', [
            'teacher_id' => $teacher->id,
            'type' => 'master_class',
            'date' => '2026-09-23',
            'start' => '11:00',
        ])->assertUnprocessable()->assertJsonPath('error.code', 'MASTER_CLASS_MONTHLY_LIMIT');
    }

    public function test_rate_student_is_offered_after_master_class_join_not_introduction(): void
    {
        [$student, $teacher] = $this->makeStudentWithTeacher();
        $intro = $this->book($student, $teacher, '10:00');
        Carbon::setTestNow(Carbon::parse('2026-09-16 09:58:00', 'Asia/Kolkata'));
        $this->withToken($this->tokenFor($student->user))->postJson('/api/v1/student/bookings/'.$intro->id.'/join')->assertOk();
        Carbon::setTestNow(Carbon::parse('2026-09-16 10:31:00', 'Asia/Kolkata'));

        $introDay = $this->withToken($this->tokenFor($teacher->user))
            ->getJson('/api/v1/teacher/schedule/day?date=2026-09-16')
            ->json('data.bookings.0.attendance');
        $this->assertFalse($introDay['can_rate_student']);
        $this->assertFalse($introDay['can_edit_student_rating']);
        $this->assertNull($introDay['monthly_feedback_id']);

        $intro->update(['status' => SessionBookingStatus::Completed->value]);
        \App\Models\StudentLevelJourney::query()
            ->where('student_id', $student->id)
            ->whereNull('ended_at')
            ->update(['started_at' => Carbon::parse('2026-08-01 00:00:00', 'Asia/Kolkata')]);
        $masterId = $this->withToken($this->tokenFor($student->user))->postJson('/api/v1/student/bookings', [
            'teacher_id' => $teacher->id,
            'type' => 'master_class',
            'date' => '2026-09-16',
            'start' => '11:00',
        ])->assertCreated()->json('data.id');

        Carbon::setTestNow(Carbon::parse('2026-09-16 10:58:00', 'Asia/Kolkata'));
        $this->withToken($this->tokenFor($student->user))->postJson('/api/v1/student/bookings/'.$masterId.'/join')->assertOk();
        Carbon::setTestNow(Carbon::parse('2026-09-16 11:31:00', 'Asia/Kolkata'));

        $masterDay = $this->withToken($this->tokenFor($teacher->user))
            ->getJson('/api/v1/teacher/schedule/day?date=2026-09-16')
            ->json('data.bookings');
        $masterAttendance = collect($masterDay)->firstWhere('id', $masterId)['attendance'];
        $this->assertTrue($masterAttendance['can_rate_student']);
        $this->assertFalse($masterAttendance['can_edit_student_rating']);
        $this->assertFalse($masterAttendance['can_report_student_did_not_join']);

        MonthlyFeedback::query()->create([
            'student_id' => $student->id,
            'master_teacher_id' => $teacher->id,
            'session_booking_id' => $masterId,
            'year' => 2026,
            'month' => 9,
            'session_date' => '2026-09-16',
            'submitted_at' => now(),
        ]);

        $afterRating = $this->withToken($this->tokenFor($teacher->user))
            ->getJson('/api/v1/teacher/schedule/day?date=2026-09-16')
            ->json('data.bookings');
        $rated = collect($afterRating)->firstWhere('id', $masterId)['attendance'];
        $this->assertFalse($rated['can_rate_student']);
        $this->assertTrue($rated['can_edit_student_rating']);
        $this->assertNotNull($rated['monthly_feedback_id']);

        $this->assertSame(2, ClassJoinEvent::query()->count());
        Carbon::setTestNow(Carbon::parse('2026-09-20 10:00:00', 'Asia/Kolkata'));
        $this->assertSame(2, app(AttendanceService::class)->pruneJoinEvents());
        $this->assertSame(0, ClassJoinEvent::query()->count());
        $this->assertSame(2, ClassAttendance::query()->count());
    }

    public function test_missed_introduction_call_allows_one_last_chance_and_both_can_report(): void
    {
        [$student, $teacher] = $this->makeStudentWithTeacher();
        $token = $this->tokenFor($student->user);
        $first = $this->book($student, $teacher, '10:00');
        $first->update([
            'starts_at' => Carbon::parse('2026-09-15 10:00:00', 'Asia/Kolkata'),
            'ends_at' => Carbon::parse('2026-09-15 10:30:00', 'Asia/Kolkata'),
            'date' => '2026-09-15',
        ]);

        $this->withToken($token)->getJson('/api/v1/student/bookings/eligibility')
            ->assertOk()
            ->assertJsonPath('data.can_book_introduction', true)
            ->assertJsonPath('data.introduction_last_chance', true)
            ->assertJsonPath('data.can_book_master_class', false);

        $second = $this->withToken($token)->postJson('/api/v1/student/bookings', [
            'teacher_id' => $teacher->id,
            'type' => 'introduction_call',
            'date' => '2026-09-17',
            'start' => '11:00',
        ])->assertCreated();

        $this->assertSame(2, $second->json('data.attempt_number'));
        $this->assertTrue($second->json('data.attendance.is_last_chance'));
        $this->assertStringContainsString('last chance', strtolower((string) $second->json('data.attendance.last_chance_message')));

        $this->withToken($token)->postJson('/api/v1/student/bookings', [
            'teacher_id' => $teacher->id,
            'type' => 'introduction_call',
            'date' => '2026-09-18',
            'start' => '11:00',
        ])
            ->assertStatus(409)
            ->assertJsonPath('error.code', 'CONFLICT');

        Carbon::setTestNow(Carbon::parse('2026-09-17 11:31:00', 'Asia/Kolkata'));
        $bookingId = $second->json('data.id');

        $this->withToken($token)->postJson(
            '/api/v1/student/bookings/'.$bookingId.'/attendance-reports',
            ['message' => 'The Master Teacher did not join the Introduction Call.'],
        )->assertCreated();

        $this->withToken($this->tokenFor($teacher->user))->postJson(
            '/api/v1/teacher/schedule/bookings/'.$bookingId.'/attendance-reports',
            ['message' => 'The student did not join the Introduction Call.'],
        )->assertCreated();
    }

    public function test_teacher_whatsapp_is_only_enabled_during_class_and_targets_the_current_student(): void
    {
        [$student, $teacher] = $this->makeStudentWithTeacher();
        $other = $this->makeSecondStudent();
        $first = $this->book($student, $teacher, '10:00');
        $second = $this->book($other, $teacher, '10:30');
        $teacherToken = $this->tokenFor($teacher->user);
        $login = rtrim((string) config('app.frontend_url'), '/').'/login';

        $before = $this->withToken($teacherToken)
            ->getJson('/api/v1/teacher/schedule/day?date=2026-09-16')
            ->assertOk()
            ->json('data.bookings');
        $beforeById = collect($before)->keyBy('id');
        $this->assertFalse($beforeById[$first->id]['attendance']['can_whatsapp_student']);
        $this->assertSame('before', $beforeById[$first->id]['attendance']['whatsapp_window']);
        $this->assertSame('Available when class starts', $beforeById[$first->id]['attendance']['whatsapp_hint']);
        $this->assertArrayNotHasKey('phone', $beforeById[$first->id]['attendance']);

        $this->withToken($teacherToken)
            ->postJson('/api/v1/teacher/schedule/bookings/'.$first->id.'/whatsapp')
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'WHATSAPP_WINDOW');

        Carbon::setTestNow(Carbon::parse('2026-09-16 10:00:00', 'Asia/Kolkata'));
        $atStart = $this->withToken($teacherToken)
            ->getJson('/api/v1/teacher/schedule/day?date=2026-09-16')
            ->json('data.bookings');
        $atStartById = collect($atStart)->keyBy('id');
        $this->assertTrue($atStartById[$first->id]['attendance']['can_whatsapp_student']);
        $this->assertSame('during', $atStartById[$first->id]['attendance']['whatsapp_window']);
        $this->assertFalse($atStartById[$second->id]['attendance']['can_whatsapp_student']);

        $ready = $this->withToken($teacherToken)
            ->postJson('/api/v1/teacher/schedule/bookings/'.$first->id.'/whatsapp')
            ->assertOk()
            ->json('data');

        $this->assertSame($student->full_name, $ready['student_name']);
        $this->assertSame($teacher->full_name, $ready['teacher_name']);
        $this->assertSame($login, $ready['login_url']);
        $this->assertSame('91'.$student->phone, $ready['phone']);
        $this->assertStringContainsString('https://wa.me/91'.$student->phone.'?text=', $ready['whatsapp_url']);
        parse_str((string) parse_url($ready['whatsapp_url'], PHP_URL_QUERY), $query);
        $this->assertSame($ready['message'], $query['text'] ?? null);
        $this->assertStringContainsString($student->full_name, $ready['message']);
        $this->assertStringContainsString($teacher->full_name, $ready['message']);
        $this->assertStringContainsString($login, $ready['message']);
        $this->assertStringNotContainsString('meet.google', strtolower($ready['message']));
        $this->assertStringNotContainsString('meet.google.com', $ready['whatsapp_url']);
        $this->assertSame(0, (int) ClassAttendance::query()->where('booking_id', $first->id)->value('student_join_count'));
        $this->assertSame(0, AttendanceIssue::query()->count());
        $this->assertSame(0, ClassJoinEvent::query()->count());

        $this->withToken($teacherToken)->postJson('/api/v1/teacher/schedule/bookings/'.$first->id.'/whatsapp')->assertOk();
        $this->withToken($teacherToken)->postJson('/api/v1/teacher/schedule/bookings/'.$first->id.'/whatsapp')->assertOk();
        $this->assertSame(1, ClassAttendance::query()->where('booking_id', $first->id)->count());
        $this->assertSame(1, ClassAttendance::query()->whereNotNull('teacher_whatsapp_reminder_sent_at')->count());
        $this->assertSame(0, ClassJoinEvent::query()->count());
        $this->assertSame(0, AttendanceIssue::query()->count());

        Carbon::setTestNow(Carbon::parse('2026-09-16 10:15:00', 'Asia/Kolkata'));
        $during = $this->withToken($teacherToken)
            ->getJson('/api/v1/teacher/schedule/day?date=2026-09-16')
            ->json('data.bookings');
        $this->assertTrue(collect($during)->firstWhere('id', $first->id)['attendance']['can_whatsapp_student']);

        Carbon::setTestNow(Carbon::parse('2026-09-16 10:30:00', 'Asia/Kolkata'));
        $atEnd = $this->withToken($teacherToken)
            ->getJson('/api/v1/teacher/schedule/day?date=2026-09-16')
            ->json('data.bookings');
        $atEndById = collect($atEnd)->keyBy('id');
        $this->assertFalse($atEndById[$first->id]['attendance']['can_whatsapp_student']);
        $this->assertSame('Class ended', $atEndById[$first->id]['attendance']['whatsapp_hint']);
        $this->assertTrue($atEndById[$second->id]['attendance']['can_whatsapp_student']);

        $this->withToken($teacherToken)
            ->postJson('/api/v1/teacher/schedule/bookings/'.$first->id.'/whatsapp')
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'WHATSAPP_WINDOW')
            ->assertJsonPath('message', 'Class ended');

        $next = $this->withToken($teacherToken)
            ->postJson('/api/v1/teacher/schedule/bookings/'.$second->id.'/whatsapp')
            ->assertOk()
            ->json('data');
        $this->assertSame($other->full_name, $next['student_name']);
        $this->assertSame('91'.$other->phone, $next['phone']);
        $this->assertStringNotContainsString($student->phone, $next['whatsapp_url']);

        $other->update(['phone' => null, 'whatsapp_number' => null]);
        $this->withToken($teacherToken)
            ->postJson('/api/v1/teacher/schedule/bookings/'.$second->id.'/whatsapp')
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'STUDENT_WHATSAPP_UNAVAILABLE')
            ->assertJsonPath('message', 'Student WhatsApp number is not available.');

        $outsider = $this->makeMasterTeacher();
        $this->withToken($this->tokenFor($outsider->user))
            ->postJson('/api/v1/teacher/schedule/bookings/'.$second->id.'/whatsapp')
            ->assertNotFound();

        $this->withToken($this->tokenFor($student->user))
            ->postJson('/api/v1/teacher/schedule/bookings/'.$first->id.'/whatsapp')
            ->assertForbidden();
    }

    public function test_held_master_class_this_month_cannot_be_booked_again(): void
    {
        [$student, $teacher] = $this->makeStudentWithTeacher();
        $intro = $this->book($student, $teacher, '10:00');
        Carbon::setTestNow(Carbon::parse('2026-09-16 09:58:00', 'Asia/Kolkata'));
        $this->withToken($this->tokenFor($student->user))->postJson('/api/v1/student/bookings/'.$intro->id.'/join')->assertOk();
        Carbon::setTestNow(Carbon::parse('2026-09-16 10:31:00', 'Asia/Kolkata'));
        $intro->update(['status' => SessionBookingStatus::Completed->value]);
        \App\Models\StudentLevelJourney::query()
            ->where('student_id', $student->id)
            ->whereNull('ended_at')
            ->update(['started_at' => Carbon::parse('2026-08-01 00:00:00', 'Asia/Kolkata')]);

        $masterId = $this->withToken($this->tokenFor($student->user))->postJson('/api/v1/student/bookings', [
            'teacher_id' => $teacher->id,
            'type' => 'master_class',
            'date' => '2026-09-16',
            'start' => '11:00',
        ])->assertCreated()->json('data.id');

        Carbon::setTestNow(Carbon::parse('2026-09-16 10:58:00', 'Asia/Kolkata'));
        $this->withToken($this->tokenFor($student->user))->postJson('/api/v1/student/bookings/'.$masterId.'/join')->assertOk();
        Carbon::setTestNow(Carbon::parse('2026-09-16 11:31:00', 'Asia/Kolkata'));

        $this->withToken($this->tokenFor($student->user))->getJson('/api/v1/student/bookings/eligibility')
            ->assertOk()
            ->assertJsonPath('data.can_book_master_class', false)
            ->assertJsonPath('data.master_class_remaining', 0);

        $this->withToken($this->tokenFor($student->user))->postJson('/api/v1/student/bookings', [
            'teacher_id' => $teacher->id,
            'type' => 'master_class',
            'date' => '2026-09-20',
            'start' => '11:00',
        ])->assertUnprocessable()->assertJsonPath('error.code', 'MASTER_CLASS_MONTHLY_LIMIT');
    }

    private function makeSecondStudent(): StudentProfile
    {
        $admin = $this->makeAdmin();
        $id = $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/students', [
            'name' => 'Attend Student Two',
            'email' => 'attend-2-'.uniqid().'@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => '97'.random_int(10000000, 99999999),
            'class_grade' => 6,
            'gender' => 'male',
        ])->assertCreated()->json('data.id');

        return StudentProfile::query()->with('user')->findOrFail($id);
    }

    private function book(StudentProfile $student, TeacherProfile $teacher, string $start): SessionBooking
    {
        $id = $this->withToken($this->tokenFor($student->user))->postJson('/api/v1/student/bookings', [
            'teacher_id' => $teacher->id,
            'type' => 'introduction_call',
            'date' => '2026-09-16',
            'start' => $start,
        ])->assertCreated()->json('data.id');

        return SessionBooking::query()->findOrFail($id);
    }
}
