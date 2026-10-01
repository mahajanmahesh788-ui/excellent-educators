<?php

namespace Tests\Feature\Api\V1;

use App\Enums\AttendanceIssueType;
use App\Enums\RoleName;
use App\Enums\SessionBookingStatus;
use App\Enums\SessionBookingType;
use App\Models\AttendanceIssue;
use App\Models\Dimension;
use App\Models\SessionBooking;
use App\Models\StudentProfile;
use App\Models\TeacherProfile;
use App\Models\User;
use App\Support\AppClock;
use Database\Seeders\DimensionSeeder;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class MasterTeacherDashboardTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed([RoleSeeder::class, DimensionSeeder::class]);
    }

    public function test_master_teacher_dashboard_returns_rating_progress(): void
    {
        [$admin, $student, $master] = $this->assignedPair();
        $this->pastMeeting($student, $master);
        $dimension = Dimension::query()->where('code', 'TW')->firstOrFail();
        ['year' => $year, 'month' => $month] = AppClock::currentYearMonth();

        $this->withToken($this->tokenFor($master->user->fresh()))->postJson(
            "/api/v1/master-teacher/students/{$student->id}/feedback",
            [
                ...$this->dimensionRatingPayload(8),
                'session_date' => now()->toDateString(),
            ],
        )->assertCreated();

        $this->withToken($this->tokenFor($master->user))->getJson('/api/v1/master-teacher/dashboard')
            ->assertOk()
            ->assertJsonPath('data.counts.assigned_students', 1)
            ->assertJsonPath('data.counts.rated_this_month', 1)
            ->assertJsonPath('data.counts.not_rated_this_month', 0)
            ->assertJsonPath('data.counts.total_ratings', 1)
            ->assertJsonPath('data.current_month.year', $year)
            ->assertJsonPath('data.current_month.month', $month)
            ->assertJsonCount(1, 'data.by_month')
            ->assertJsonPath('data.by_month.0.students_rated', 1)
            ->assertJsonCount(0, 'data.pending_students');
    }

    public function test_not_rated_counts_only_held_meetings_without_attendance_complaints(): void
    {
        [, $student, $master] = $this->assignedPair();
        $booking = $this->pastMeeting($student, $master);

        $this->withToken($this->tokenFor($master->user->fresh()))->getJson('/api/v1/master-teacher/dashboard')
            ->assertOk()
            ->assertJsonPath('data.counts.assigned_students', 1)
            ->assertJsonPath('data.counts.rated_this_month', 0)
            ->assertJsonPath('data.counts.not_rated_this_month', 1)
            ->assertJsonPath('data.pending_students.0.id', $student->id);

        AttendanceIssue::query()->create([
            'booking_id' => $booking->id,
            'reporter_user_id' => $master->user_id,
            'reporter_role' => 'master_teacher',
            'issue_type' => AttendanceIssueType::StudentDidNotJoin->value,
            'message' => 'Student did not attend',
            'verification_status' => 'pending',
        ]);

        $this->withToken($this->tokenFor($master->user->fresh()))->getJson('/api/v1/master-teacher/dashboard')
            ->assertOk()
            ->assertJsonPath('data.counts.not_rated_this_month', 0)
            ->assertJsonPath('data.pending_students', []);
    }

    public function test_introduction_call_does_not_put_student_on_dashboard_to_rate(): void
    {
        [, $student, $master] = $this->assignedPair();
        $starts = AppClock::now()->subHours(2);
        $ends = AppClock::now()->subHour();
        SessionBooking::query()->create([
            'student_id' => $student->id,
            'teacher_id' => $master->id,
            'type' => SessionBookingType::IntroductionCall->value,
            'date' => $starts->toDateString(),
            'starts_at' => $starts,
            'ends_at' => $ends,
            'status' => SessionBookingStatus::Completed->value,
        ]);

        $this->withToken($this->tokenFor($master->user->fresh()))->getJson('/api/v1/master-teacher/dashboard')
            ->assertOk()
            ->assertJsonPath('data.counts.not_rated_this_month', 0)
            ->assertJsonPath('data.pending_students', []);

        $this->pastMeeting($student, $master);

        $this->withToken($this->tokenFor($master->user->fresh()))->getJson('/api/v1/master-teacher/dashboard')
            ->assertOk()
            ->assertJsonPath('data.counts.not_rated_this_month', 1)
            ->assertJsonPath('data.pending_students.0.can_rate', true)
            ->assertJsonPath('data.pending_students.0.can_edit_rating', false);
    }

    public function test_common_teacher_cannot_access_master_teacher_dashboard(): void
    {
        $teacher = $this->makeTeacher([RoleName::CommonTeacher->value], 'mt-dash-common@excellenteducators.test');

        $this->withToken($this->tokenFor($teacher->user))->getJson('/api/v1/master-teacher/dashboard')
            ->assertForbidden();
    }

    public function test_master_teacher_can_list_levels_and_promote_assigned_student(): void
    {
        [$admin, $student, $master] = $this->assignedPair();

        $levels = $this->withToken($this->tokenFor($master->user))
            ->getJson('/api/v1/master-teacher/levels')
            ->assertOk()
            ->json('data');
        $this->assertNotEmpty($levels);

        $currentLevelId = $student->fresh()->level_id;
        $target = collect($levels)->firstWhere(fn ($level) => ($level['id'] ?? null) !== $currentLevelId);
        if ($target === null) {
            $targetLevel = \App\Models\AcademicLevel::query()->create([
                'name' => 'Level Promote Target',
                'academic_year' => 2026,
                'status' => 'active',
            ]);
            $target = ['id' => $targetLevel->id];
        }

        $requestId = $this->withToken($this->tokenFor($master->user))->postJson(
            "/api/v1/master-teacher/students/{$student->id}/promote",
            ['level_id' => $target['id']],
        )
            ->assertCreated()
            ->assertJsonPath('data.request_type', 'promote_student')
            ->assertJsonPath('data.status', 'pending')
            ->json('data.id');

        // Level does not change until admin accepts.
        $this->assertSame($currentLevelId, $student->fresh()->level_id);

        $this->withToken($this->tokenFor($admin))->postJson(
            "/api/v1/admin/requests/{$requestId}/resolve",
            ['apply_action' => true],
        )->assertOk()->assertJsonPath('data.status', 'completed');

        $this->assertSame($target['id'], $student->fresh()->level_id);

        // Level 1 mentor is not on the destination level — access ends after accept.
        $this->withToken($this->tokenFor($master->user))
            ->getJson("/api/v1/master-teacher/students/{$student->id}")
            ->assertForbidden();

        $this->assertDatabaseMissing('master_teacher_assignments', [
            'student_id' => $student->id,
            'teacher_id' => $master->id,
            'ended_at' => null,
        ]);
    }

    public function test_level_two_student_shows_only_to_level_two_teacher(): void
    {
        $admin = $this->makeAdmin();
        $level1Teacher = $this->makeTeacher(['master_teacher'], 'mt-l1-only@excellenteducators.test');
        $level2Teacher = $this->makeTeacher(['master_teacher'], 'mt-l2-only@excellenteducators.test');
        $phone = (string) (9100000000 + random_int(1000, 9999));

        $studentId = $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/students', [
            'name' => 'Level Scope Student',
            'email' => 'mt-level-scope-student@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => $phone,
            'class_grade' => 5,
            'gender' => 'male',
        ])->assertCreated()->json('data.id');

        $student = StudentProfile::query()->findOrFail($studentId);
        $level1 = $student->level_id;
        $this->assertNotNull($level1);

        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/levels/{$level1}/teachers", [
            'teacher_id' => $level1Teacher->id,
        ])->assertOk();

        $level2 = \App\Models\AcademicLevel::query()->create([
            'name' => 'Level 2 Scope',
            'academic_year' => 2026,
            'status' => 'active',
        ]);
        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/levels/{$level2->id}/teachers", [
            'teacher_id' => $level2Teacher->id,
        ])->assertOk();

        $this->withToken($this->tokenFor($level1Teacher->user))
            ->getJson("/api/v1/master-teacher/students/{$student->id}")
            ->assertOk();

        $this->withToken($this->tokenFor($level2Teacher->user))
            ->getJson("/api/v1/master-teacher/students/{$student->id}")
            ->assertForbidden();

        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/students/{$student->id}/promote", [
            'level_id' => $level2->id,
        ])->assertOk();

        $this->assertSame($level2->id, $student->fresh()->level_id);

        $this->withToken($this->tokenFor($level1Teacher->user))
            ->getJson("/api/v1/master-teacher/students/{$student->id}")
            ->assertForbidden();

        $this->withToken($this->tokenFor($level1Teacher->user))
            ->getJson('/api/v1/master-teacher/students')
            ->assertOk()
            ->assertJsonMissing(['id' => $student->id]);

        $this->withToken($this->tokenFor($level2Teacher->user))
            ->getJson("/api/v1/master-teacher/students/{$student->id}")
            ->assertOk()
            ->assertJsonPath('data.level.id', $level2->id);

        $list = $this->withToken($this->tokenFor($level2Teacher->user))
            ->getJson('/api/v1/master-teacher/students')
            ->assertOk()
            ->json('data');
        $this->assertTrue(collect($list)->contains(fn ($row) => ($row['id'] ?? null) === $student->id));
    }

    public function test_master_teacher_receives_rejection_notification_for_level_upgrade(): void
    {
        $admin = $this->makeAdmin();
        $master = $this->makeTeacher(['master_teacher'], 'mt-level-only@excellenteducators.test');
        $phone = (string) (9100000000 + random_int(1000, 9999));

        $studentId = $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/students', [
            'name' => 'Level Only Student',
            'email' => 'mt-level-only-student@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => $phone,
            'class_grade' => 5,
            'gender' => 'male',
        ])->assertCreated()->json('data.id');

        $student = StudentProfile::query()->findOrFail($studentId);
        $level1 = $student->level_id;
        $this->assertNotNull($level1);

        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/levels/{$level1}/teachers", [
            'teacher_id' => $master->id,
        ])->assertOk();

        $level2 = \App\Models\AcademicLevel::query()->create([
            'name' => 'Level 2 After Promote',
            'academic_year' => 2026,
            'status' => 'active',
        ]);

        $requestId = $this->withToken($this->tokenFor($master->user))->postJson(
            "/api/v1/master-teacher/students/{$student->id}/promote",
            ['level_id' => $level2->id],
        )->assertCreated()->json('data.id');

        $this->withToken($this->tokenFor($admin))->postJson(
            "/api/v1/admin/requests/{$requestId}/resolve",
            ['reject' => true],
        )->assertOk()->assertJsonPath('data.status', 'rejected');

        $this->assertSame($level1, $student->fresh()->level_id);

        $this->assertDatabaseHas('user_notifications', [
            'user_id' => $master->user_id,
            'type' => 'admin_request_rejected',
        ]);
    }

    /**
     * @return array{0: User, 1: StudentProfile, 2: TeacherProfile}
     */
    private function assignedPair(): array
    {
        $admin = $this->makeAdmin();
        $master = $this->makeTeacher(['master_teacher'], 'mt-dash-master@excellenteducators.test');
        $phone = (string) (9100000000 + random_int(1000, 9999));

        $studentId = $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/students', [
            'name' => 'Dashboard Student',
            'email' => 'mt-dash-student@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => $phone,
            'class_grade' => 5,
            'gender' => 'male',
        ])->assertCreated()->json('data.id');

        $this->withToken($this->tokenFor($admin))->putJson("/api/v1/admin/students/{$studentId}/mentor", [
            'teacher_id' => $master->id,
        ])->assertOk();

        return [$admin, StudentProfile::query()->findOrFail($studentId), $master];
    }

    private function pastMeeting(StudentProfile $student, TeacherProfile $teacher): SessionBooking
    {
        $starts = AppClock::now()->subHours(2);
        $ends = AppClock::now()->subHour();

        return SessionBooking::query()->create([
            'student_id' => $student->id,
            'teacher_id' => $teacher->id,
            'type' => SessionBookingType::MasterClass->value,
            'date' => $starts->toDateString(),
            'starts_at' => $starts,
            'ends_at' => $ends,
            'status' => SessionBookingStatus::Completed->value,
        ]);
    }

    /**
     * @param  list<string>  $roles
     */
    private function makeTeacher(array $roles, string $email): TeacherProfile
    {
        $user = User::factory()->create(['email' => $email]);
        $user->syncRoles($roles);

        $profile = TeacherProfile::query()->create([
            'user_id' => $user->id,
            'full_name' => $user->name,
            'status' => 'active',
        ]);
        $profile->setRelation('user', $user);

        return $profile;
    }
}
