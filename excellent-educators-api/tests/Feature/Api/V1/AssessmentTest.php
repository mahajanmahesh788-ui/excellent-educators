<?php

namespace Tests\Feature\Api\V1;

use App\Enums\RoleName;
use App\Models\CareerCompassLevel;
use App\Models\TeacherProfile;
use App\Models\User;
use Database\Seeders\CareerCompassLevelSeeder;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\PermissionRegistrar;
use Tests\TestCase;

class AssessmentTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed([RoleSeeder::class, CareerCompassLevelSeeder::class]);
    }

    public function test_common_teacher_creates_assessment_and_records_scores_with_versioning(): void
    {
        $admin = $this->makeAdmin();
        $adminToken = $this->tokenFor($admin);
        $cc1 = CareerCompassLevel::query()->where('code', 'cc1')->firstOrFail();

        $batchId = $this->withToken($adminToken)->postJson('/api/v1/admin/batches', [
            'career_compass_level_id' => $cc1->id,
            'name' => 'Assess Batch',
            'academic_year' => 2026,
        ])->assertCreated()->json('data.id');

        $studentId = $this->withToken($adminToken)->postJson('/api/v1/admin/students', [
            'name' => 'Score Student',
            'email' => 'score@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => '9876543210',
            'career_compass_level_id' => $cc1->id,
        ])->assertCreated()->json('data.id');

        $this->withToken($adminToken)->postJson("/api/v1/admin/batches/{$batchId}/students", [
            'student_id' => $studentId,
        ])->assertOk();

        $common = $this->makeTeacher(['common_teacher'], 'common@excellenteducators.test');
        $this->withToken($adminToken)->postJson("/api/v1/admin/batches/{$batchId}/teacher", [
            'teacher_id' => $common->id,
        ])->assertOk();

        $this->app['auth']->forgetGuards();
        app(PermissionRegistrar::class)->forgetCachedPermissions();

        $teacherToken = $this->tokenFor($common->user->fresh());

        $assessmentId = $this->withToken($teacherToken)->postJson("/api/v1/teacher/batches/{$batchId}/assessments", [
            'title' => 'Unit test 1',
            'max_score' => 20,
            'status' => 'published',
        ])->assertCreated()
            ->assertJsonPath('data.title', 'Unit test 1')
            ->assertJsonPath('data.version', 1)
            ->json('data.id');

        $this->withToken($teacherToken)->putJson("/api/v1/teacher/batches/{$batchId}/assessments/{$assessmentId}/scores", [
            'scores' => [
                ['student_id' => $studentId, 'score' => 18, 'notes' => 'Strong'],
            ],
        ])->assertOk()
            ->assertJsonPath('data.assessment.scored_count', 1);

        $this->withToken($teacherToken)->putJson("/api/v1/teacher/batches/{$batchId}/assessments/{$assessmentId}", [
            'title' => 'Unit test 1 revised',
            'max_score' => 25,
        ])->assertOk()
            ->assertJsonPath('data.version', 2)
            ->assertJsonPath('data.title', 'Unit test 1 revised');

        $this->assertDatabaseHas('assessment_versions', [
            'assessment_id' => $assessmentId,
            'version' => 1,
            'title' => 'Unit test 1',
        ]);

        $this->assertDatabaseHas('assessment_scores', [
            'assessment_id' => $assessmentId,
            'student_id' => $studentId,
            'version' => 1,
            'score' => '18.00',
        ]);
    }

    public function test_admin_updates_batch_and_unassigns_teachers(): void
    {
        $admin = $this->makeAdmin();
        $token = $this->tokenFor($admin);
        $cc1 = CareerCompassLevel::query()->where('code', 'cc1')->firstOrFail();

        $batchId = $this->withToken($token)->postJson('/api/v1/admin/batches', [
            'career_compass_level_id' => $cc1->id,
            'name' => 'Old name',
            'academic_year' => 2026,
        ])->assertCreated()->json('data.id');

        $this->withToken($token)->putJson("/api/v1/admin/batches/{$batchId}", [
            'name' => 'New name',
            'status' => 'closed',
        ])->assertOk()
            ->assertJsonPath('data.name', 'New name')
            ->assertJsonPath('data.status', 'closed');

        $common = $this->makeTeacher(['common_teacher'], 'common2@excellenteducators.test');
        $this->withToken($token)->postJson("/api/v1/admin/batches/{$batchId}/teacher", [
            'teacher_id' => $common->id,
        ])->assertOk();

        $this->withToken($token)->deleteJson("/api/v1/admin/batches/{$batchId}/teacher")
            ->assertOk()
            ->assertJsonPath('data.common_teacher', null);

        $studentId = $this->withToken($token)->postJson('/api/v1/admin/students', [
            'name' => 'Mentee',
            'email' => 'mentee@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => '9876543211',
            'career_compass_level_id' => $cc1->id,
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

    private function makeAdmin(): User
    {
        $user = User::factory()->create(['email' => 'ops-assess@excellenteducators.test']);
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
        return $user->createToken('test')->plainTextToken;
    }
}
