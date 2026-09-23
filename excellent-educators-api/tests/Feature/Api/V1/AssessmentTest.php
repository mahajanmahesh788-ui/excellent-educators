<?php

namespace Tests\Feature\Api\V1;

use App\Models\TeacherProfile;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AssessmentTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed([RoleSeeder::class]);
    }

    public function test_admin_updates_batch(): void
    {
        $admin = $this->makeAdmin();
        $token = $this->tokenFor($admin);

        $batchId = $this->withToken($token)->postJson('/api/v1/admin/batches', [
            'name' => 'Old name',
            'academic_year' => 2026,
        ])->assertCreated()->json('data.id');

        $this->withToken($token)->putJson("/api/v1/admin/batches/{$batchId}", [
            'name' => 'New name',
            'status' => 'closed',
        ])->assertOk()
            ->assertJsonPath('data.name', 'New name')
            ->assertJsonPath('data.status', 'closed');

        $studentId = $this->withToken($token)->postJson('/api/v1/admin/students', [
            'name' => 'Mentee',
            'email' => 'mentee@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => '9876543211',
            'class_grade' => 5,
            'gender' => 'male',
        ])->assertCreated()->json('data.id');

        $master = $this->makeTeacher(['master_teacher'], 'master@excellenteducators.test');
        $this->withToken($token)->putJson("/api/v1/admin/students/{$studentId}/mentor", [
            'teacher_id' => $master->id,
        ])->assertOk()
            ->assertJsonPath('data.master_teacher.full_name', $master->full_name);

        $this->withToken($token)->deleteJson("/api/v1/admin/students/{$studentId}/mentor")
            ->assertOk()
            ->assertJsonPath('data.master_teacher', null);
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
