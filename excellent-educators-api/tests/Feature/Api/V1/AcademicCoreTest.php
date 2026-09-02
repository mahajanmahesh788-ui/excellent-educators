<?php

namespace Tests\Feature\Api\V1;

use App\Enums\RoleName;
use App\Models\Batch;
use App\Models\CareerCompassLevel;
use App\Models\StudentProfile;
use App\Models\TeacherProfile;
use App\Models\User;
use Database\Seeders\CareerCompassLevelSeeder;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AcademicCoreTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed([RoleSeeder::class, CareerCompassLevelSeeder::class]);
    }

    public function test_admin_creates_student_with_generated_code(): void
    {
        $admin = $this->makeAdmin();
        $cc1 = CareerCompassLevel::query()->where('code', 'cc1')->firstOrFail();

        $response = $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/students', [
            'name' => 'Rahul Sharma',
            'email' => 'rahul@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => '9876543210',
            'career_compass_level_id' => $cc1->id,
            'academic_year' => 2026,
        ]);

        $response
            ->assertCreated()
            ->assertJsonPath('data.student_code', 'CC1-APS-26-0001')
            ->assertJsonPath('data.phone', '9876543210')
            ->assertJsonPath('data.class_grade', 6);

        $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/students', [
            'name' => 'No Phone',
            'email' => 'nophone@excellenteducators.test',
            'password' => 'StudentPass1!',
            'career_compass_level_id' => $cc1->id,
        ])->assertUnprocessable();

        $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/students', [
            'name' => 'Rahul 2',
            'email' => 'rahul2@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => '9876543211',
            'career_compass_level_id' => $cc1->id,
            'academic_year' => 2026,
            'student_code' => 'CC1-APS-26-9999',
        ])->assertUnprocessable();
    }

    public function test_email_and_phone_must_be_unique(): void
    {
        $admin = $this->makeAdmin();
        $token = $this->tokenFor($admin);
        $cc1 = CareerCompassLevel::query()->where('code', 'cc1')->firstOrFail();

        $this->withToken($token)->postJson('/api/v1/admin/students', [
            'name' => 'First Student',
            'email' => 'unique@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => '9876543210',
            'career_compass_level_id' => $cc1->id,
        ])->assertCreated();

        $this->withToken($token)->postJson('/api/v1/admin/students', [
            'name' => 'Duplicate Email',
            'email' => 'unique@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => '9876543211',
            'career_compass_level_id' => $cc1->id,
        ])
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'VALIDATION_ERROR')
            ->assertJsonStructure(['error' => ['details' => ['email']]]);

        $this->withToken($token)->postJson('/api/v1/admin/students', [
            'name' => 'Duplicate Phone',
            'email' => 'other@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => '+91 9876543210',
            'career_compass_level_id' => $cc1->id,
        ])
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'VALIDATION_ERROR')
            ->assertJsonStructure(['error' => ['details' => ['phone']]]);

        $this->withToken($token)->postJson('/api/v1/admin/teachers', [
            'name' => 'Teacher One',
            'email' => 'unique@excellenteducators.test',
            'password' => 'TeacherPass1!',
            'roles' => ['common_teacher'],
        ])
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'VALIDATION_ERROR')
            ->assertJsonStructure(['error' => ['details' => ['email']]]);
    }

    public function test_batch_rejects_over_active_limit_and_assignments_keep_history(): void
    {
        config(['excellent_educators.batch.max_active_students' => 2]);

        $admin = $this->makeAdmin();
        $token = $this->tokenFor($admin);
        $cc1 = CareerCompassLevel::query()->where('code', 'cc1')->firstOrFail();

        $batchId = $this->withToken($token)->postJson('/api/v1/admin/batches', [
            'career_compass_level_id' => $cc1->id,
            'name' => 'Level 1-A',
            'academic_year' => 2026,
        ])->assertCreated()->json('data.id');

        $studentIds = [];
        foreach (['one', 'two', 'three'] as $i => $name) {
            $studentIds[] = $this->withToken($token)->postJson('/api/v1/admin/students', [
                'name' => 'Student '.$name,
                'email' => $name.'@excellenteducators.test',
                'password' => 'StudentPass1!',
                'phone' => '900000000'.($i + 1),
                'career_compass_level_id' => $cc1->id,
                'academic_year' => 2026,
            ])->json('data.id');
        }

        $this->withToken($token)->postJson("/api/v1/admin/batches/{$batchId}/students", [
            'student_id' => $studentIds[0],
        ])->assertOk();
        $this->withToken($token)->postJson("/api/v1/admin/batches/{$batchId}/students", [
            'student_id' => $studentIds[1],
        ])->assertOk();
        $this->withToken($token)->postJson("/api/v1/admin/batches/{$batchId}/students", [
            'student_id' => $studentIds[2],
        ])
            ->assertStatus(409)
            ->assertJsonPath('error.code', 'BATCH_FULL');

        $common = $this->makeTeacher([RoleName::CommonTeacher->value], 'common@excellenteducators.test');
        $common2 = $this->makeTeacher([RoleName::CommonTeacher->value], 'common2@excellenteducators.test');

        $this->withToken($token)->postJson("/api/v1/admin/batches/{$batchId}/teacher", [
            'teacher_id' => $common->id,
        ])->assertOk()->assertJsonPath('data.common_teacher.id', $common->id);

        $this->withToken($token)->postJson("/api/v1/admin/batches/{$batchId}/teacher", [
            'teacher_id' => $common2->id,
        ])->assertOk()->assertJsonPath('data.common_teacher.id', $common2->id);

        $this->assertDatabaseCount('batch_teachers', 2);
        $this->assertDatabaseHas('batch_teachers', [
            'teacher_id' => $common->id,
        ]);
        $this->assertNotNull(
            Batch::query()->findOrFail($batchId)->teacherAssignments()->where('teacher_id', $common->id)->value('ended_at'),
        );

        $mentor = $this->makeTeacher([RoleName::MasterTeacher->value], 'mentor@excellenteducators.test');
        $this->withToken($token)->putJson("/api/v1/admin/students/{$studentIds[0]}/mentor", [
            'teacher_id' => $mentor->id,
        ])->assertOk()->assertJsonPath('data.master_teacher.id', $mentor->id);

        $this->app['auth']->forgetGuards();
        $this->withToken($this->tokenFor($common2->user))->getJson('/api/v1/teacher/batches')
            ->assertOk()
            ->assertJsonPath('data.0.name', 'Level 1-A');

        $this->app['auth']->forgetGuards();
        $this->withToken($this->tokenFor($mentor->user))->getJson('/api/v1/master-teacher/students')
            ->assertOk()
            ->assertJsonPath('data.0.id', $studentIds[0]);

        $this->app['auth']->forgetGuards();
        $studentUser = User::query()->findOrFail(
            StudentProfile::query()->findOrFail($studentIds[0])->user_id,
        );
        $this->withToken($this->tokenFor($studentUser))->getJson('/api/v1/student/profile')
            ->assertOk()
            ->assertJsonPath('data.id', $studentIds[0]);

        $this->app['auth']->forgetGuards();
        $this->withToken($this->tokenFor($common2->user))->getJson('/api/v1/teacher/profile')
            ->assertOk()
            ->assertJsonPath('data.email', $common2->user->email);

        $this->app['auth']->forgetGuards();
        $this->withToken($this->tokenFor($mentor->user))->getJson('/api/v1/teacher/profile')
            ->assertOk()
            ->assertJsonPath('data.email', $mentor->user->email);
    }

    public function test_non_admin_cannot_create_students(): void
    {
        $teacher = $this->makeTeacher([RoleName::CommonTeacher->value], 't@excellenteducators.test');
        $cc1 = CareerCompassLevel::query()->where('code', 'cc1')->firstOrFail();

        $this->withToken($this->tokenFor($teacher->user))->postJson('/api/v1/admin/students', [
            'name' => 'Nope',
            'email' => 'nope@excellenteducators.test',
            'password' => 'StudentPass1!',
            'career_compass_level_id' => $cc1->id,
            'class_grade' => 7,
        ])->assertForbidden();
    }

    public function test_admin_dashboard_returns_summary_counts(): void
    {
        $admin = $this->makeAdmin();
        $cc1 = CareerCompassLevel::query()->where('code', 'cc1')->firstOrFail();

        $this->withToken($this->tokenFor($admin))->getJson('/api/v1/admin/dashboard')
            ->assertOk()
            ->assertJsonPath('data.counts.active_students', 0)
            ->assertJsonPath('data.counts.active_batches', 0);

        $batchId = $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/batches', [
            'career_compass_level_id' => $cc1->id,
            'name' => 'Level 1-A',
            'academic_year' => 2026,
        ])->assertCreated()->json('data.id');

        $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/students', [
            'name' => 'Dash Student',
            'email' => 'dash@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => '9876543210',
            'career_compass_level_id' => $cc1->id,
        ])->assertCreated();

        $this->withToken($this->tokenFor($admin))->getJson('/api/v1/admin/dashboard')
            ->assertOk()
            ->assertJsonPath('data.counts.active_students', 1)
            ->assertJsonPath('data.counts.active_batches', 1)
            ->assertJsonPath('data.counts.students_without_batch', 1)
            ->assertJsonPath('data.counts.students_without_master_teacher', 1)
            ->assertJsonPath('data.counts.batches_without_common_teacher', 1)
            ->assertJsonPath('data.career_compass.0.code', 'cc1');
    }

    public function test_admin_student_and_batch_list_filters_and_phone_search(): void
    {
        $admin = $this->makeAdmin();
        $token = $this->tokenFor($admin);
        $cc1 = CareerCompassLevel::query()->where('code', 'cc1')->firstOrFail();

        $batchId = $this->withToken($token)->postJson('/api/v1/admin/batches', [
            'career_compass_level_id' => $cc1->id,
            'name' => 'Filter Batch',
            'academic_year' => 2026,
        ])->assertCreated()->json('data.id');

        $unassignedId = $this->withToken($token)->postJson('/api/v1/admin/students', [
            'name' => 'Unassigned Student',
            'email' => 'unassigned@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => '9123456789',
            'career_compass_level_id' => $cc1->id,
        ])->assertCreated()->json('data.id');

        $assignedId = $this->withToken($token)->postJson('/api/v1/admin/students', [
            'name' => 'Assigned Student',
            'email' => 'assigned@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => '9988776655',
            'career_compass_level_id' => $cc1->id,
        ])->assertCreated()->json('data.id');

        $this->withToken($token)->postJson("/api/v1/admin/batches/{$batchId}/students", [
            'student_id' => $assignedId,
        ])->assertOk();

        $this->withToken($token)->getJson('/api/v1/admin/students?without_batch=true&status=active')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $unassignedId);

        $this->withToken($token)->getJson('/api/v1/admin/students?search=9123456789')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $unassignedId);

        $this->withToken($token)->getJson('/api/v1/admin/students?without_master_teacher=1&status=active')
            ->assertOk()
            ->assertJsonCount(2, 'data');

        $this->withToken($token)->getJson('/api/v1/admin/batches?without_common_teacher=1&status=active')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $batchId);

        config(['excellent_educators.batch.max_active_students' => 1]);

        $this->withToken($token)->getJson('/api/v1/admin/batches?full=1')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $batchId);
    }

    private function makeAdmin(): User
    {
        $user = User::factory()->create(['email' => 'ops@excellenteducators.test']);
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
