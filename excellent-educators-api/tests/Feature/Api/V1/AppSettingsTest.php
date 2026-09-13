<?php

namespace Tests\Feature\Api\V1;

use App\Enums\RoleName;
use App\Models\User;
use App\Support\AppSettings;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AppSettingsTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed([RoleSeeder::class]);
    }

    public function test_admin_can_read_and_update_batch_student_limit(): void
    {
        $admin = $this->makeAdmin();
        $token = $this->tokenFor($admin);

        $this->withToken($token)->getJson('/api/v1/admin/settings')
            ->assertOk()
            ->assertJsonPath('data.max_active_students', 50)
            ->assertJsonPath('data.items.0.key', 'max_active_students');

        $this->withToken($token)->putJson('/api/v1/admin/settings', [
            'max_active_students' => 25,
        ])
            ->assertOk()
            ->assertJsonPath('data.max_active_students', 25);

        $this->assertSame(25, app(AppSettings::class)->maxActiveStudents());

        $this->withToken($token)->putJson('/api/v1/admin/settings', [
            'max_active_students' => 0,
        ])->assertUnprocessable();
    }

    public function test_teacher_cannot_change_settings(): void
    {
        $user = User::factory()->create(['email' => 'mt-settings@excellenteducators.test']);
        $user->assignRole(RoleName::MasterTeacher->value);

        $this->withToken($this->tokenFor($user))
            ->putJson('/api/v1/admin/settings', ['max_active_students' => 10])
            ->assertForbidden();
    }

    private function makeAdmin(): User
    {
        $user = User::factory()->create(['email' => 'ops-settings@excellenteducators.test']);
        $user->assignRole(RoleName::OperationalAdmin->value);

        return $user;
    }

    private function tokenFor(User $user): string
    {
        $this->app['auth']->forgetGuards();

        return $user->createToken('test')->plainTextToken;
    }
}
