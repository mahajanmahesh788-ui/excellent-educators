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
use Spatie\Permission\PermissionRegistrar;
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
                'session_date' => now()->toDateString(),
                'items' => [[
                    'target_type' => 'dimension',
                    'target_id' => $dimension->id,
                    'rating' => 8,
                    'positive_points' => 'Good work',
                    'areas_for_improvement' => 'Focus',
                    'recommended_next_action' => 'Practice',
                ]],
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
            ->assertJsonPath('data.pending_students.0.can_edit_rating', true)
            ->assertJsonPath('data.pending_students.0.can_rate', false);
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

    private function makeAdmin(): User
    {
        $user = User::factory()->create(['email' => 'mt-dash-admin@excellenteducators.test']);
        $user->assignRole(RoleName::OperationalAdmin->value);

        return $user;
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

    private function tokenFor(User $user): string
    {
        $this->app['auth']->forgetGuards();
        app(PermissionRegistrar::class)->forgetCachedPermissions();

        return $user->fresh()->createToken('test')->plainTextToken;
    }
}
