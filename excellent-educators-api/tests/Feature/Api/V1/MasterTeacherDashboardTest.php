<?php

namespace Tests\Feature\Api\V1;

use App\Enums\RoleName;
use App\Models\CareerCompassLevel;
use App\Models\Dimension;
use App\Models\StudentProfile;
use App\Models\TeacherProfile;
use App\Models\User;
use App\Support\AppClock;
use Database\Seeders\CareerCompassLevelSeeder;
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
        $this->seed([RoleSeeder::class, CareerCompassLevelSeeder::class, DimensionSeeder::class]);
    }

    public function test_master_teacher_dashboard_returns_rating_progress(): void
    {
        [$admin, $student, $master] = $this->assignedPair();
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
            ->assertJsonPath('data.by_month.0.students_rated', 1);
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
        $cc1 = CareerCompassLevel::query()->where('code', 'cc1')->firstOrFail();
        $master = $this->makeTeacher(['master_teacher'], 'mt-dash-master@excellenteducators.test');
        $phone = (string) (9100000000 + random_int(1000, 9999));

        $studentId = $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/students', [
            'name' => 'Dashboard Student',
            'email' => 'mt-dash-student@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => $phone,
            'career_compass_level_id' => $cc1->id,
        ])->assertCreated()->json('data.id');

        $this->withToken($this->tokenFor($admin))->putJson("/api/v1/admin/students/{$studentId}/mentor", [
            'teacher_id' => $master->id,
        ])->assertOk();

        return [$admin, StudentProfile::query()->findOrFail($studentId), $master];
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
