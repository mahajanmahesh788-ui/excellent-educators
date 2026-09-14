<?php

namespace Tests\Feature\Api\V1;

use App\Enums\RoleName;
use App\Models\Batch;
use App\Models\StudentProfile;
use App\Models\TeacherProfile;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AcademicCoreTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed([RoleSeeder::class]);
    }

    public function test_admin_creates_student_with_generated_code(): void
    {
        $admin = $this->makeAdmin();

        $response = $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/students', [
            'name' => 'Rahul Sharma',
            'email' => 'rahul@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => '9876543210',
            'class_grade' => 5,
            'academic_year' => 2026,
        ]);

        $response
            ->assertCreated()
            ->assertJsonPath('data.student_code', '26-0001')
            ->assertJsonPath('data.phone', '9876543210')
            ->assertJsonPath('data.class_grade', 5);

        $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/students', [
            'name' => 'No Phone',
            'email' => 'nophone@excellenteducators.test',
            'password' => 'StudentPass1!',
            'class_grade' => 5,
        ])->assertUnprocessable();

        $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/students', [
            'name' => 'Rahul 2',
            'email' => 'rahul2@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => '9876543211',
            'class_grade' => 5,
            'academic_year' => 2026,
            'student_code' => '26-9999',
        ])->assertUnprocessable();
    }

    public function test_email_and_phone_must_be_unique(): void
    {
        $admin = $this->makeAdmin();
        $token = $this->tokenFor($admin);

        $this->withToken($token)->postJson('/api/v1/admin/students', [
            'name' => 'First Student',
            'email' => 'unique@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => '9876543210',
            'class_grade' => 5,
        ])->assertCreated();

        $this->withToken($token)->postJson('/api/v1/admin/students', [
            'name' => 'Duplicate Email',
            'email' => 'unique@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => '9876543211',
            'class_grade' => 5,
        ])
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'VALIDATION_ERROR')
            ->assertJsonStructure(['error' => ['details' => ['email']]]);

        $this->withToken($token)->postJson('/api/v1/admin/students', [
            'name' => 'Duplicate Phone',
            'email' => 'other@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => '+91 9876543210',
            'class_grade' => 5,
        ])
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'VALIDATION_ERROR')
            ->assertJsonStructure(['error' => ['details' => ['phone']]]);

        $this->withToken($token)->postJson('/api/v1/admin/teachers', [
            'name' => 'Teacher One',
            'email' => 'unique@excellenteducators.test',
            'password' => 'TeacherPass1!',
            'roles' => ['master_teacher'],
        ])
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'VALIDATION_ERROR')
            ->assertJsonStructure(['error' => ['details' => ['email']]]);
    }

    public function test_admin_creates_teacher_with_address_and_default_master_teacher_role(): void
    {
        $admin = $this->makeAdmin();
        $token = $this->tokenFor($admin);

        $response = $this->withToken($token)->postJson('/api/v1/admin/teachers', [
            'name' => 'Meera Nair',
            'email' => 'meera@excellenteducators.test',
            'password' => 'TeacherPass1!',
            'phone' => '9876500001',
            'address' => '42 Residency Road, Bangalore',
        ]);

        $response
            ->assertCreated()
            ->assertJsonPath('data.full_name', 'Meera Nair')
            ->assertJsonPath('data.address', '42 Residency Road, Bangalore')
            ->assertJsonPath('data.roles.0', 'master_teacher');
    }

    public function test_batch_rejects_over_active_limit_and_assignments_keep_history(): void
    {
        config(['excellent_educators.batch.max_active_students' => 2]);

        $admin = $this->makeAdmin();
        $token = $this->tokenFor($admin);

        $batchId = $this->withToken($token)->postJson('/api/v1/admin/batches', [
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
                'class_grade' => 5,
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

        $mentor = $this->makeTeacher([RoleName::MasterTeacher->value], 'mentor@excellenteducators.test');
        $this->withToken($token)->putJson("/api/v1/admin/students/{$studentIds[0]}/mentor", [
            'teacher_id' => $mentor->id,
        ])->assertOk()->assertJsonPath('data.master_teacher.id', $mentor->id);

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
        $this->withToken($this->tokenFor($mentor->user))->getJson('/api/v1/teacher/profile')
            ->assertOk()
            ->assertJsonPath('data.email', $mentor->user->email);
    }

    public function test_non_admin_cannot_create_students(): void
    {
        $teacher = $this->makeTeacher([RoleName::MasterTeacher->value], 't@excellenteducators.test');

        $this->withToken($this->tokenFor($teacher->user))->postJson('/api/v1/admin/students', [
            'name' => 'Nope',
            'email' => 'nope@excellenteducators.test',
            'password' => 'StudentPass1!',
            'class_grade' => 7,
        ])->assertForbidden();
    }

    public function test_admin_dashboard_returns_summary_counts(): void
    {
        $admin = $this->makeAdmin();

        $initialActiveBatches = Batch::query()->where('status', 'active')->count();

        $this->withToken($this->tokenFor($admin))->getJson('/api/v1/admin/dashboard')
            ->assertOk()
            ->assertJsonPath('data.counts.active_students', 0)
            ->assertJsonPath('data.counts.active_batches', $initialActiveBatches);

        $batchId = $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/batches', [
            'name' => 'Level 1-A',
            'academic_year' => 2026,
        ])->assertCreated()->json('data.id');

        $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/students', [
            'name' => 'Dash Student',
            'email' => 'dash@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => '9876543210',
            'class_grade' => 5,
        ])->assertCreated();

        $this->withToken($this->tokenFor($admin))->getJson('/api/v1/admin/dashboard')
            ->assertOk()
            ->assertJsonPath('data.counts.active_students', 1)
            ->assertJsonPath('data.counts.total_students', 1)
            ->assertJsonPath('data.counts.active_batches', $initialActiveBatches + 1)
            ->assertJsonStructure([
                'data' => [
                    'by_level',
                    'top_students',
                    'top_teachers',
                ],
            ]);
    }

    public function test_admin_student_and_batch_list_filters_and_phone_search(): void
    {
        $admin = $this->makeAdmin();
        $token = $this->tokenFor($admin);

        $batchId = $this->withToken($token)->postJson('/api/v1/admin/batches', [
            'name' => 'Filter Batch',
            'academic_year' => 2026,
        ])->assertCreated()->json('data.id');

        $unassignedId = $this->withToken($token)->postJson('/api/v1/admin/students', [
            'name' => 'Unassigned Student',
            'email' => 'unassigned@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => '9123456789',
            'class_grade' => 5,
        ])->assertCreated()->json('data.id');

        $assignedId = $this->withToken($token)->postJson('/api/v1/admin/students', [
            'name' => 'Assigned Student',
            'email' => 'assigned@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => '9988776655',
            'class_grade' => 5,
        ])->assertCreated()->json('data.id');

        $unassignedProfile = StudentProfile::query()->findOrFail($unassignedId);
        $this->withToken($token)->deleteJson("/api/v1/admin/batches/{$unassignedProfile->activeEnrollment->batch_id}/students/{$unassignedId}")->assertOk();

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

        config(['excellent_educators.batch.max_active_students' => 1]);

        $this->withToken($token)->getJson('/api/v1/admin/batches?full=1&search=Filter+Batch')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $batchId);
    }

    public function test_admin_creates_student_with_class_grade_and_address(): void
    {
        $admin = $this->makeAdmin();

        $response = $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/students', [
            'name' => 'Aarav Patel',
            'email' => 'aarav@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => '9123456780',
            'class_grade' => 5,
            'address' => 'Flat 402, Green Meadows, Mumbai',
            'academic_year' => 2026,
        ]);

        $response
            ->assertCreated()
            ->assertJsonPath('data.student_code', '26-0001')
            ->assertJsonPath('data.class_grade', 5)
            ->assertJsonPath('data.address', 'Flat 402, Green Meadows, Mumbai');

        $response10 = $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/students', [
            'name' => 'Priya Singh',
            'email' => 'priya@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => '9123456781',
            'class_grade' => 10,
            'academic_year' => 2026,
        ]);

        $response10
            ->assertCreated()
            ->assertJsonPath('data.student_code', '26-0002')
            ->assertJsonPath('data.class_grade', 10);
    }

    public function test_admin_can_create_level_and_duplicate_names_are_rejected(): void
    {
        $admin = $this->makeAdmin();
        $token = $this->tokenFor($admin);

        // Can create level without career_compass_level_id
        $this->withToken($token)->postJson('/api/v1/admin/batches', [
            'name' => 'Level 2',
            'academic_year' => 2026,
        ])->assertCreated()
            ->assertJsonPath('data.name', 'Level 2')
            ->assertJsonPath('data.academic_year', 2026);

        // Duplicate level name must be rejected
        $this->withToken($token)->postJson('/api/v1/admin/batches', [
            'name' => 'Level 2',
            'academic_year' => 2026,
        ])->assertStatus(422)
            ->assertJsonPath('error.code', 'VALIDATION_ERROR')
            ->assertJsonPath('error.details.name.0', 'The level name has already been taken.');
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
