<?php

namespace Tests\Feature\Api\V1;

use App\Models\SessionBooking;
use App\Models\StudentProfile;
use App\Models\TeacherProfile;
use App\Scheduling\SlotGrid;
use Database\Seeders\CareerCompassLevelSeeder;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Tests\TestCase;

class SchedulingTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed([RoleSeeder::class, CareerCompassLevelSeeder::class]);
        Carbon::setTestNow(Carbon::parse('2026-09-15 08:00:00', 'Asia/Kolkata'));
    }

    public function test_slot_grid_has_twenty_eight_slots(): void
    {
        $this->assertCount(34, SlotGrid::starts());
        $this->assertSame('06:00', SlotGrid::starts()[0]);
        $this->assertSame('22:30', SlotGrid::starts()[33]);
        $this->assertSame(['09:00', '09:30', '10:00', '10:30'], SlotGrid::startsCovering('09:00', '11:00'));
    }

    public function test_teacher_can_set_breaks_and_they_block_availability(): void
    {
        $teacher = $this->makeMasterTeacher();
        $token = $this->tokenFor($teacher->user);

        $this->withToken($token)->putJson('/api/v1/teacher/schedule/breaks', [
            'breakfast_start' => '09:00',
            'lunch_start' => '13:00',
        ])->assertOk();

        $day = $this->withToken($token)->getJson('/api/v1/teacher/schedule/day?date=2026-09-16')
            ->assertOk()
            ->json('data');

        $byStart = collect($day['slots'])->keyBy('start');
        $this->assertSame('breakfast', $byStart['09:00']['status']);
        $this->assertSame('breakfast', $byStart['09:30']['status']);
        $this->assertSame('lunch', $byStart['13:00']['status']);
        $this->assertSame('available', $byStart['10:00']['status']);
        $this->assertCount(34, $day['slots']);
    }

    public function test_leave_with_bookings_enters_reassignment_pending_and_empty_leave_stays_pending(): void
    {
        [$student, $teacher] = $this->makeStudentWithTeacher();
        $this->book($student, $teacher, 'introduction_call', '2026-09-16', '10:00');

        $token = $this->tokenFor($teacher->user);
        $withBooking = $this->withToken($token)->postJson('/api/v1/teacher/schedule/leaves', [
            'date' => '2026-09-16',
            'is_full_day' => false,
            'reason' => 'Family visit',
            'start_time' => '09:00',
            'end_time' => '11:00',
        ])->assertCreated()->json('data');

        $this->assertSame('reassignment_pending', $withBooking['status']);
        $this->assertSame(1, $withBooking['affected_count']);
        $this->assertSame(0, $withBooking['reassigned_count']);

        $day = $this->withToken($token)->getJson('/api/v1/teacher/schedule/day?date=2026-09-16')->json('data');
        $byStart = collect($day['slots'])->keyBy('start');
        // Pending leave does not paint calendar leave; booking still shows.
        $this->assertSame('booked', $byStart['10:00']['status']);
        $this->assertSame('available', $byStart['09:00']['status']);

        $withoutBooking = $this->withToken($token)->postJson('/api/v1/teacher/schedule/leaves', [
            'date' => '2026-09-16',
            'is_full_day' => false,
            'reason' => 'Personal work',
            'slot_starts' => ['16:00', '16:30'],
        ])->assertCreated()->json('data');

        $this->assertSame('pending', $withoutBooking['status']);
        $this->assertSame(0, $withoutBooking['affected_count']);
    }

    public function test_student_must_complete_introduction_before_master_class_and_monthly_limit(): void
    {
        [$student, $teacher] = $this->makeStudentWithTeacher();
        $token = $this->tokenFor($student->user);

        $this->withToken($token)->getJson('/api/v1/student/bookings/eligibility')
            ->assertOk()
            ->assertJsonPath('data.can_book_introduction', true)
            ->assertJsonPath('data.can_book_master_class', false);

        $this->withToken($token)->postJson('/api/v1/student/bookings', [
            'teacher_id' => $teacher->id,
            'type' => 'master_class',
            'date' => '2026-09-16',
            'start' => '11:00',
        ])
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'INTRODUCTION_REQUIRED');

        $this->withToken($token)->postJson('/api/v1/student/bookings', [
            'teacher_id' => $teacher->id,
            'type' => 'introduction_call',
            'date' => '2026-09-16',
            'start' => '11:00',
        ])->assertCreated();

        $this->withToken($token)->getJson('/api/v1/student/bookings/eligibility')
            ->assertOk()
            ->assertJsonPath('data.can_book_introduction', false);

        $intro = SessionBooking::query()->first();
        $intro->update([
            'status' => 'completed',
            'starts_at' => Carbon::parse('2026-09-10 11:00:00', 'Asia/Kolkata'),
            'ends_at' => Carbon::parse('2026-09-10 11:30:00', 'Asia/Kolkata'),
            'date' => '2026-09-10',
        ]);

        // Journey started this month → Master Class opens next month
        $this->withToken($token)->getJson('/api/v1/student/bookings/eligibility')
            ->assertOk()
            ->assertJsonPath('data.master_class_opens_next_month', true)
            ->assertJsonPath('data.can_book_master_class', false);

        $this->withToken($token)->postJson('/api/v1/student/bookings', [
            'teacher_id' => $teacher->id,
            'type' => 'master_class',
            'date' => '2026-09-18',
            'start' => '11:00',
        ])
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'MASTER_CLASS_OPENS_NEXT_MONTH');

        // Simulate batch activated previous month so Master Class is unlocked
        \App\Models\StudentLevelJourney::query()
            ->where('student_id', $student->id)
            ->whereNull('ended_at')
            ->update(['started_at' => Carbon::parse('2026-08-01 00:00:00', 'Asia/Kolkata')]);

        $this->withToken($token)->getJson('/api/v1/student/bookings/eligibility')
            ->assertOk()
            ->assertJsonPath('data.master_class_opens_next_month', false)
            ->assertJsonPath('data.can_book_master_class', true);

        $first = $this->withToken($token)->postJson('/api/v1/student/bookings', [
            'teacher_id' => $teacher->id,
            'type' => 'master_class',
            'date' => '2026-09-18',
            'start' => '11:00',
        ])->assertCreated();

        $this->assertSame(1, $first->json('data.attempt_number'));

        $this->withToken($token)->getJson('/api/v1/student/bookings/eligibility')
            ->assertOk()
            ->assertJsonPath('data.master_class_remaining', 0)
            ->assertJsonPath('data.can_book_master_class', false);

        $this->withToken($token)->postJson('/api/v1/student/bookings', [
            'teacher_id' => $teacher->id,
            'type' => 'master_class',
            'date' => '2026-09-20',
            'start' => '12:00',
        ])
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'MASTER_CLASS_MONTHLY_LIMIT');

        SessionBooking::query()->where('type', 'master_class')->first()?->update([
            'starts_at' => Carbon::parse('2026-09-12 11:00:00', 'Asia/Kolkata'),
            'ends_at' => Carbon::parse('2026-09-12 11:30:00', 'Asia/Kolkata'),
            'date' => '2026-09-12',
        ]);

        $this->withToken($token)->getJson('/api/v1/student/bookings/eligibility')
            ->assertOk()
            ->assertJsonPath('data.can_book_master_class', false);

        $this->withToken($token)->postJson('/api/v1/student/bookings', [
            'teacher_id' => $teacher->id,
            'type' => 'master_class',
            'date' => '2026-09-20',
            'start' => '12:00',
        ])
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'MASTER_CLASS_MONTHLY_LIMIT');
    }

    public function test_student_with_three_master_classes_can_book_one_by_one(): void
    {
        [$student, $teacher] = $this->makeStudentWithTeacher();
        $student->update(['master_classes_per_month' => 3]);
        $token = $this->tokenFor($student->user);

        $intro = $this->book($student, $teacher, 'introduction_call', '2026-09-16', '11:00');
        $intro->update(['status' => 'completed']);
        \App\Models\StudentLevelJourney::query()
            ->where('student_id', $student->id)
            ->whereNull('ended_at')
            ->update(['started_at' => Carbon::parse('2026-08-01 00:00:00', 'Asia/Kolkata')]);

        $this->book($student, $teacher, 'master_class', '2026-09-18', '11:00');
        SessionBooking::query()->where('type', 'master_class')->latest('starts_at')->first()?->update(['status' => 'completed']);

        $this->withToken($token)->getJson('/api/v1/student/bookings/eligibility')
            ->assertOk()
            ->assertJsonPath('data.master_class_remaining', 2)
            ->assertJsonPath('data.can_book_master_class', true);

        $extra = $this->withToken($token)->postJson('/api/v1/student/bookings', [
            'teacher_id' => $teacher->id,
            'type' => 'master_class',
            'date' => '2026-09-19',
            'start' => '11:00',
        ])->assertCreated();
        $this->assertFalse((bool) $extra->json('data.attendance.is_last_chance'));
        $this->assertNull($extra->json('data.attendance.last_chance_message'));
        $this->withToken($token)->getJson('/api/v1/student/bookings/eligibility')
            ->assertOk()
            ->assertJsonPath('data.master_class_remaining', 1);

        $admin = $this->makeAdmin();
        $this->withToken($this->tokenFor($admin))->getJson('/api/v1/admin/students/'.$student->id.'/history')
            ->assertOk()
            ->assertJsonFragment(['type' => 'master_class_booked']);
    }

    public function test_student_availability_marks_blocked_slots_and_overlap_is_rejected(): void
    {
        [$student, $teacher] = $this->makeStudentWithTeacher();
        $teacherToken = $this->tokenFor($teacher->user);
        $this->withToken($teacherToken)->putJson('/api/v1/teacher/schedule/breaks', [
            'breakfast_start' => '09:00',
            'lunch_start' => '13:00',
        ])->assertOk();
        $this->withToken($teacherToken)->postJson('/api/v1/teacher/schedule/leaves', [
            'date' => '2026-09-16',
            'reason' => 'Appointment',
            'start_time' => '16:00',
            'end_time' => '17:00',
        ])->assertCreated();

        $this->book($student, $teacher, 'introduction_call', '2026-09-16', '11:30');

        $token = $this->tokenFor($student->user);
        $slots = $this->withToken($token)->getJson(
            '/api/v1/student/bookings/availability?teacher_id='.$teacher->id.'&date=2026-09-16',
        )->assertOk()->json('data.slots');

        $byStart = collect($slots)->keyBy('start');
        $this->assertArrayNotHasKey('09:00', $byStart->all());
        $this->assertArrayNotHasKey('11:30', $byStart->all());
        $this->assertArrayNotHasKey('16:00', $byStart->all());
        $this->assertSame('available', $byStart['10:00']['status']);
        $this->assertTrue(collect($slots)->every(fn ($slot) => $slot['status'] === 'available'));

        $other = $this->makeSecondStudent($teacher);
        $this->withToken($this->tokenFor($other->user))->postJson('/api/v1/student/bookings', [
            'teacher_id' => $teacher->id,
            'type' => 'introduction_call',
            'date' => '2026-09-16',
            'start' => '11:30',
        ])
            ->assertStatus(409)
            ->assertJsonPath('error.code', 'SLOT_UNAVAILABLE');
    }

    public function test_student_can_reschedule_to_a_free_slot(): void
    {
        [$student, $teacher] = $this->makeStudentWithTeacher();
        $booking = $this->book($student, $teacher, 'introduction_call', '2026-09-16', '11:00');
        $token = $this->tokenFor($student->user);

        $this->withToken($token)->putJson('/api/v1/student/bookings/'.$booking->id, [
            'teacher_id' => $teacher->id,
            'date' => '2026-09-17',
            'start' => '14:00',
        ])
            ->assertOk()
            ->assertJsonPath('data.start', '14:00')
            ->assertJsonPath('data.type', 'introduction_call');

        $this->assertTrue(
            \App\Models\UserNotification::query()
                ->where('user_id', $teacher->user_id)
                ->where('type', \App\Enums\NotificationType::SessionRescheduled->value)
                ->exists(),
        );
    }

    public function test_teacher_is_notified_when_student_books(): void
    {
        [$student, $teacher] = $this->makeStudentWithTeacher();
        $this->book($student, $teacher, 'introduction_call', '2026-09-16', '11:00');

        $notification = \App\Models\UserNotification::query()
            ->where('user_id', $teacher->user_id)
            ->where('type', \App\Enums\NotificationType::SessionBooked->value)
            ->first();

        $this->assertNotNull($notification);
        $this->assertStringContainsString($student->full_name, $notification->body);
    }

    public function test_admin_can_view_teacher_calendar_and_delete_booking(): void
    {
        $admin = $this->makeAdmin();
        [$student, $teacher] = $this->makeStudentWithTeacher();
        $booking = $this->book($student, $teacher, 'introduction_call', '2026-09-16', '11:00');

        $this->withToken($this->tokenFor($admin))->getJson(
            '/api/v1/admin/schedule/day?teacher_id='.$teacher->id.'&date=2026-09-16',
        )->assertOk()->assertJsonPath('data.bookings.0.id', $booking->id);

        $this->withToken($this->tokenFor($admin))
            ->deleteJson('/api/v1/admin/schedule/bookings/'.$booking->id)
            ->assertOk();
    }

    public function test_leave_requires_reason_and_cannot_use_or_delete_past_dates(): void
    {
        $teacher = $this->makeMasterTeacher();
        $token = $this->tokenFor($teacher->user);

        $this->withToken($token)->postJson('/api/v1/teacher/schedule/leaves', [
            'date' => '2026-09-14',
            'is_full_day' => true,
            'reason' => 'Travel',
        ])
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'VALIDATION_ERROR');

        $created = $this->withToken($token)->postJson('/api/v1/teacher/schedule/leaves', [
            'date' => '2026-09-16',
            'is_full_day' => true,
            'reason' => 'Family function',
        ])->assertCreated()->json('data');

        $this->assertSame('Family function', $created['reason']);
        $this->assertSame('pending', $created['status']);
        $this->assertNotEmpty($created['items']);
        $leaveId = $created['items'][0]['id'];
        $this->assertNotNull($created['items'][0]['created_at']);

        Carbon::setTestNow(Carbon::parse('2026-09-17 08:00:00', 'Asia/Kolkata'));

        $this->withToken($token)
            ->deleteJson('/api/v1/teacher/schedule/leaves/'.$leaveId)
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'LEAVE_DATE_PASSED');
    }

    private function makeSecondStudent(TeacherProfile $teacher): StudentProfile
    {
        $admin = $this->makeAdmin();
        $id = $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/students', [
            'name' => 'Second Student',
            'email' => 'slot-student-2-'.uniqid().'@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => '97'.random_int(10000000, 99999999),
            'class_grade' => 6,
            'gender' => 'male',
        ])->assertCreated()->json('data.id');

        return StudentProfile::query()->with('user')->findOrFail($id);
    }

    private function book(StudentProfile $student, TeacherProfile $teacher, string $type, string $date, string $start): SessionBooking
    {
        $id = $this->withToken($this->tokenFor($student->user))->postJson('/api/v1/student/bookings', [
            'teacher_id' => $teacher->id,
            'type' => $type,
            'date' => $date,
            'start' => $start,
        ])->assertCreated()->json('data.id');

        return SessionBooking::query()->findOrFail($id);
    }

    public function test_live_introduction_or_master_class_cannot_be_booked_again(): void
    {
        [$student, $teacher] = $this->makeStudentWithTeacher();
        $token = $this->tokenFor($student->user);

        $this->book($student, $teacher, 'introduction_call', '2026-09-16', '10:00');
        Carbon::setTestNow(Carbon::parse('2026-09-16 10:10:00', 'Asia/Kolkata'));

        $this->withToken($token)->getJson('/api/v1/student/bookings/eligibility')
            ->assertOk()
            ->assertJsonPath('data.can_book_introduction', false)
            ->assertJsonPath('data.has_upcoming_introduction', true);

        $this->withToken($token)->postJson('/api/v1/student/bookings', [
            'teacher_id' => $teacher->id,
            'type' => 'introduction_call',
            'date' => '2026-09-17',
            'start' => '11:00',
        ])
            ->assertStatus(409);
    }

    public function test_teacher_can_fetch_all_booking_history_across_dates(): void
    {
        [$student, $teacher] = $this->makeStudentWithTeacher();
        $intro = $this->book($student, $teacher, 'introduction_call', '2026-09-16', '10:00');
        $intro->update(['status' => 'completed']);
        \App\Models\StudentLevelJourney::query()
            ->where('student_id', $student->id)
            ->whereNull('ended_at')
            ->update(['started_at' => Carbon::parse('2026-08-01 00:00:00', 'Asia/Kolkata')]);
        $this->book($student, $teacher, 'master_class', '2026-09-18', '11:00');

        $token = $this->tokenFor($teacher->user);
        $payload = $this->withToken($token)->getJson('/api/v1/teacher/schedule/bookings')
            ->assertOk()
            ->json('data');

        $this->assertCount(2, $payload);
        $dates = collect($payload)->pluck('date')->all();
        $this->assertContains('2026-09-16', $dates);
        $this->assertContains('2026-09-18', $dates);
    }
}
