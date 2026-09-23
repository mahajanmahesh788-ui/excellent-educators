<?php

namespace Tests\Feature\Api\V1;

use App\Enums\RoleName;
use App\Enums\SessionBookingStatus;
use App\Enums\SessionBookingType;
use App\Models\Dimension;
use App\Models\SessionBooking;
use App\Models\StudentProfile;
use App\Models\TeacherLeave;
use App\Models\TeacherProfile;
use App\Models\User;
use App\Support\AppClock;
use Database\Seeders\DimensionSeeder;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminTeacherDashboardTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed([RoleSeeder::class, DimensionSeeder::class]);
    }

    public function test_admin_can_view_master_teacher_rating_progress(): void
    {
        $admin = $this->makeAdmin();
        [$student, $master] = $this->assignedMasterTeacher($admin);
        $this->pastMeeting($student, $master);
        $dimension = Dimension::query()->where('code', 'TW')->firstOrFail();
        ['year' => $year, 'month' => $month] = AppClock::currentYearMonth();

        $this->withToken($this->tokenFor($master->user))->postJson(
            "/api/v1/master-teacher/students/{$student->id}/feedback",
            [
                ...$this->dimensionRatingPayload(7),
                'session_date' => now()->toDateString(),
            ],
        )->assertCreated();

        $this->withToken($this->tokenFor($admin))->getJson("/api/v1/admin/teachers/{$master->id}/dashboard")
            ->assertOk()
            ->assertJsonPath('data.counts.assigned_students', 1)
            ->assertJsonPath('data.counts.rated_this_month', 1)
            ->assertJsonPath('data.counts.total_ratings', 1)
            ->assertJsonPath('data.current_month.year', $year)
            ->assertJsonPath('data.current_month.month', $month);
    }

    public function test_admin_teacher_dashboard_rejects_common_teacher(): void
    {
        $admin = $this->makeAdmin();
        $teacher = $this->makeTeacher([RoleName::CommonTeacher->value], 'admin-dash-common@excellenteducators.test');

        $this->withToken($this->tokenFor($admin))->getJson("/api/v1/admin/teachers/{$teacher->id}/dashboard")
            ->assertStatus(422);
    }

    public function test_admin_can_view_teacher_history_timeline(): void
    {
        $admin = $this->makeAdmin();
        [$student, $master] = $this->assignedMasterTeacher($admin);
        $this->pastMeeting($student, $master, SessionBookingType::IntroductionCall);
        $this->pastMeeting($student, $master, SessionBookingType::MasterClass);
        TeacherLeave::query()->create([
            'teacher_id' => $master->id,
            'date' => AppClock::todayString(),
            'start_time' => '06:00',
            'end_time' => '23:00',
            'is_full_day' => true,
            'reason' => 'Personal',
            'created_by' => $admin->id,
        ]);

        $this->withToken($this->tokenFor($admin))->getJson("/api/v1/admin/teachers/{$master->id}/history")
            ->assertOk()
            ->assertJsonPath('data.this_month.leave_days', 1)
            ->assertJsonPath('data.this_month.interviews', 1)
            ->assertJsonPath('data.this_month.master_classes', 1)
            ->assertJsonPath('data.all_time.interviews', 1)
            ->assertJsonPath('data.all_time.master_classes', 1)
            ->assertJsonPath('data.by_month.0.interviews', 1)
            ->assertJsonCount(3, 'data.events');
    }

    /**
     * @return array{0: StudentProfile, 1: TeacherProfile}
     */
    private function assignedMasterTeacher(User $admin): array
    {
        $master = $this->makeTeacher(['master_teacher'], 'admin-dash-master@excellenteducators.test');
        $phone = (string) (9200000000 + random_int(1000, 9999));

        $studentId = $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/students', [
            'name' => 'Admin Dashboard Student',
            'email' => 'admin-dash-student@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => $phone,
            'class_grade' => 5,
            'gender' => 'male',
        ])->assertCreated()->json('data.id');

        $this->withToken($this->tokenFor($admin))->putJson("/api/v1/admin/students/{$studentId}/mentor", [
            'teacher_id' => $master->id,
        ])->assertOk();

        return [StudentProfile::query()->findOrFail($studentId), $master];
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

    private function pastMeeting(
        StudentProfile $student,
        TeacherProfile $teacher,
        SessionBookingType $type = SessionBookingType::MasterClass,
    ): SessionBooking {
        $starts = AppClock::now()->subHours($type === SessionBookingType::IntroductionCall ? 3 : 2);
        $ends = AppClock::now()->subHours($type === SessionBookingType::IntroductionCall ? 2 : 1);

        return SessionBooking::query()->create([
            'student_id' => $student->id,
            'teacher_id' => $teacher->id,
            'type' => $type->value,
            'date' => $starts->toDateString(),
            'starts_at' => $starts,
            'ends_at' => $ends,
            'status' => SessionBookingStatus::Completed->value,
        ]);
    }
}
