<?php

namespace Tests\Feature\Api\V1;

use App\Enums\NotificationType;
use App\Models\SessionBooking;
use App\Models\StudentProfile;
use App\Models\TeacherProfile;
use App\Models\UserNotification;
use Database\Seeders\CareerCompassLevelSeeder;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Tests\TestCase;

class TeacherLeaveApprovalTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed([RoleSeeder::class, CareerCompassLevelSeeder::class]);
        Carbon::setTestNow(Carbon::parse('2026-09-15 08:00:00', 'Asia/Kolkata'));
    }

    public function test_admin_approves_leave_with_no_affected_bookings(): void
    {
        $teacher = $this->makeMasterTeacher();
        $admin = $this->makeAdmin();

        $group = $this->withToken($this->tokenFor($teacher->user))->postJson('/api/v1/teacher/schedule/leaves', [
            'date' => '2026-09-16',
            'is_full_day' => false,
            'reason' => 'Doctor',
            'slot_starts' => ['14:00'],
        ])->assertCreated()->json('data');

        $this->assertSame('pending', $group['status']);
        $this->assertTrue($group['can_approve']);

        $this->withToken($this->tokenFor($admin))
            ->postJson("/api/v1/admin/schedule/leave-requests/{$group['request_group_id']}/approve")
            ->assertOk()
            ->assertJsonPath('data.status', 'approved');

        $day = $this->withToken($this->tokenFor($teacher->user))
            ->getJson('/api/v1/teacher/schedule/day?date=2026-09-16')
            ->json('data');
        $this->assertSame('leave', collect($day['slots'])->keyBy('start')['14:00']['status']);
    }

    public function test_admin_must_reassign_all_affected_bookings_before_approve(): void
    {
        [$student, $teacher] = $this->makeStudentWithTeacher();
        $replacement = $this->makeSecondMasterTeacher($teacher);
        $admin = $this->makeAdmin();
        $booking = $this->book($student, $teacher, 'introduction_call', '2026-09-16', '10:00');

        $group = $this->withToken($this->tokenFor($teacher->user))->postJson('/api/v1/teacher/schedule/leaves', [
            'date' => '2026-09-16',
            'is_full_day' => false,
            'reason' => 'Emergency',
            'start_time' => '09:00',
            'end_time' => '11:00',
        ])->assertCreated()->json('data');

        $groupId = $group['request_group_id'];
        $this->assertSame('reassignment_pending', $group['status']);

        $this->withToken($this->tokenFor($admin))
            ->postJson("/api/v1/admin/schedule/leave-requests/{$groupId}/approve")
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'LEAVE_REASSIGNMENT_INCOMPLETE');

        $replacements = $this->withToken($this->tokenFor($admin))
            ->getJson("/api/v1/admin/schedule/leave-requests/{$groupId}/bookings/{$booking->id}/replacements")
            ->assertOk()
            ->json('data.teachers');
        $this->assertTrue(collect($replacements)->contains('id', $replacement->id));

        $this->withToken($this->tokenFor($admin))->putJson(
            "/api/v1/admin/schedule/leave-requests/{$groupId}/reassignments/{$booking->id}",
            ['replacement_teacher_id' => $replacement->id],
        )->assertOk()->assertJsonPath('data.reassigned_count', 1);

        // Pending leave blocks new bookings on original teacher.
        $this->withToken($this->tokenFor($student->user))->postJson('/api/v1/student/bookings', [
            'teacher_id' => $teacher->id,
            'type' => 'introduction_call',
            'date' => '2026-09-16',
            'start' => '09:30',
        ])->assertStatus(409);

        $this->withToken($this->tokenFor($admin))
            ->postJson("/api/v1/admin/schedule/leave-requests/{$groupId}/approve")
            ->assertOk()
            ->assertJsonPath('data.status', 'approved');

        $booking->refresh();
        $this->assertSame($replacement->id, $booking->teacher_id);
        $this->assertSame($teacher->id, $booking->reassigned_from_teacher_id);
        $this->assertNotNull($booking->reassigned_at);

        $this->assertTrue(
            UserNotification::query()
                ->where('user_id', $student->user_id)
                ->where('type', NotificationType::SessionMentorUpdated->value)
                ->exists(),
        );
    }

    public function test_partial_leave_only_affects_overlapping_bookings(): void
    {
        [$student, $teacher] = $this->makeStudentWithTeacher();
        $student2 = $this->makeSecondStudent($teacher);
        $student3 = $this->makeSecondStudent($teacher);

        $this->book($student, $teacher, 'introduction_call', '2026-09-16', '08:00');
        $this->book($student2, $teacher, 'introduction_call', '2026-09-16', '10:00');
        $this->book($student3, $teacher, 'introduction_call', '2026-09-16', '15:00');

        $leave = $this->withToken($this->tokenFor($teacher->user))->postJson('/api/v1/teacher/schedule/leaves', [
            'date' => '2026-09-16',
            'is_full_day' => false,
            'reason' => 'Partial',
            'start_time' => '09:00',
            'end_time' => '14:00',
        ])->assertCreated()->json('data');

        $this->assertSame(1, $leave['affected_count']);
        $this->assertSame('10:00', $leave['affected_bookings'][0]['start']);
    }

    public function test_admin_can_reject_and_teacher_can_cancel_pending_leave(): void
    {
        $teacher = $this->makeMasterTeacher();
        $admin = $this->makeAdmin();

        $group = $this->withToken($this->tokenFor($teacher->user))->postJson('/api/v1/teacher/schedule/leaves', [
            'date' => '2026-09-16',
            'is_full_day' => false,
            'reason' => 'Reject me',
            'slot_starts' => ['11:00'],
        ])->assertCreated()->json('data');

        $this->withToken($this->tokenFor($admin))->postJson(
            "/api/v1/admin/schedule/leave-requests/{$group['request_group_id']}/reject",
            ['reason' => 'Coverage unavailable'],
        )->assertOk()->assertJsonPath('data.status', 'rejected');

        $this->assertTrue(
            UserNotification::query()
                ->where('user_id', $teacher->user_id)
                ->where('type', NotificationType::TeacherLeaveRejected->value)
                ->exists(),
        );

        $cancelGroup = $this->withToken($this->tokenFor($teacher->user))->postJson('/api/v1/teacher/schedule/leaves', [
            'date' => '2026-09-17',
            'is_full_day' => false,
            'reason' => 'Cancel me',
            'slot_starts' => ['11:00'],
        ])->assertCreated()->json('data');

        $this->withToken($this->tokenFor($teacher->user))
            ->deleteJson('/api/v1/teacher/schedule/leaves/'.$cancelGroup['items'][0]['id'])
            ->assertOk()
            ->assertJsonPath('data.status', 'cancelled');
    }

    public function test_overlapping_leave_requests_are_rejected(): void
    {
        $teacher = $this->makeMasterTeacher();
        $token = $this->tokenFor($teacher->user);

        $this->withToken($token)->postJson('/api/v1/teacher/schedule/leaves', [
            'date' => '2026-09-16',
            'is_full_day' => false,
            'reason' => 'First',
            'start_time' => '10:00',
            'end_time' => '12:00',
        ])->assertCreated();

        $this->withToken($token)->postJson('/api/v1/teacher/schedule/leaves', [
            'date' => '2026-09-16',
            'is_full_day' => false,
            'reason' => 'Overlap',
            'start_time' => '11:00',
            'end_time' => '13:00',
        ])
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'LEAVE_OVERLAPS_LEAVE');
    }

    private function makeSecondMasterTeacher(TeacherProfile $existing): TeacherProfile
    {
        $admin = $this->makeAdmin();
        $teacher = $this->makeMasterTeacher('Replacement Mentor', 'repl-'.uniqid().'@excellenteducators.test');
        $level = $existing->academicLevels()->first()
            ?? \App\Models\AcademicLevel::query()->where('name', 'Level 1')->firstOrFail();
        $level->masterTeachers()->syncWithoutDetaching([$teacher->id]);

        return $teacher;
    }

    private function makeSecondStudent(TeacherProfile $teacher): StudentProfile
    {
        $admin = $this->makeAdmin();
        $student = $this->makeStudentViaAdmin($admin, 'Leave Student '.uniqid(), 'leave-stu');
        $level = $teacher->academicLevels()->first()
            ?? \App\Models\AcademicLevel::query()->where('name', 'Level 1')->firstOrFail();
        $level->masterTeachers()->syncWithoutDetaching([$teacher->id]);

        return $student;
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
}
