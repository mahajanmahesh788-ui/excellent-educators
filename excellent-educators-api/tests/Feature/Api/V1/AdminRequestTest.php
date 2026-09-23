<?php

namespace Tests\Feature\Api\V1;

use App\Enums\AdminRequestStatus;
use App\Models\StudentProfile;
use App\Models\TeacherProfile;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminRequestTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed([RoleSeeder::class]);
    }

    public function test_student_submits_and_lists_requests(): void
    {
        $student = $this->makeStudent('req-student@excellenteducators.test');
        $token = $this->tokenFor($student);

        $this->withToken($token)->postJson('/api/v1/student/requests', [
            'subtitle' => 'Batch change',
            'description' => 'Please move me to the morning batch.',
        ])
            ->assertCreated()
            ->assertJsonPath('data.subtitle', 'Batch change')
            ->assertJsonPath('data.status', 'pending')
            ->assertJsonPath('data.requester_type', 'student');

        $this->withToken($token)->getJson('/api/v1/student/requests')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.subtitle', 'Batch change');
    }

    public function test_teacher_submits_request(): void
    {
        $teacher = $this->makeTeacher(['master_teacher'], 'req-teacher@excellenteducators.test');
        $token = $this->tokenFor($teacher->user);

        $this->withToken($token)->postJson('/api/v1/teacher/requests', [
            'subtitle' => 'Leave approval',
            'description' => 'Need leave on Friday for a family event.',
        ])
            ->assertCreated()
            ->assertJsonPath('data.requester_type', 'teacher');

        $this->withToken($token)->getJson('/api/v1/teacher/requests')
            ->assertOk()
            ->assertJsonCount(1, 'data');
    }

    public function test_admin_lists_resolves_and_cannot_resolve_twice(): void
    {
        $admin = $this->makeAdmin();
        $adminId = $admin->id;
        $student = $this->makeStudent('req-admin@excellenteducators.test', $admin);
        $admin = User::query()->findOrFail($adminId);
        $this->assertNotSame($admin->id, $student->id);

        $studentToken = $this->tokenFor($student);

        $requestId = $this->withoutToken()->withToken($studentToken)->postJson('/api/v1/student/requests', [
            'subtitle' => 'Fee receipt',
            'description' => 'Please share last month fee receipt.',
        ])->assertCreated()->json('data.id');

        $adminToken = $this->tokenFor($admin->fresh());

        $this->withoutToken()->withToken($adminToken)->getJson('/api/v1/admin/requests')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $requestId)
            ->assertJsonPath('data.0.requester.email', 'req-admin@excellenteducators.test');

        $this->withoutToken()->withToken($adminToken)->getJson("/api/v1/admin/requests/{$requestId}")
            ->assertOk()
            ->assertJsonPath('data.description', 'Please share last month fee receipt.');

        $this->withoutToken()->withToken($adminToken)->postJson("/api/v1/admin/requests/{$requestId}/resolve")
            ->assertOk()
            ->assertJsonPath('data.status', 'completed')
            ->assertJsonPath('data.resolved_by.name', $admin->name);

        $this->assertDatabaseHas('admin_requests', [
            'id' => $requestId,
            'status' => AdminRequestStatus::Completed->value,
            'resolved_by_id' => $admin->id,
        ]);

        $this->withoutToken()->withToken($adminToken)->postJson("/api/v1/admin/requests/{$requestId}/resolve")
            ->assertStatus(409)
            ->assertJsonPath('error.code', 'CONFLICT');

        $studentToken = $this->tokenFor($student->fresh());
        $this->withoutToken()->withToken($studentToken)->getJson('/api/v1/student/requests')
            ->assertOk()
            ->assertJsonPath('data.0.status', 'completed');
    }

    public function test_validation_requires_subtitle_and_description(): void
    {
        $student = $this->makeStudent('req-val@excellenteducators.test');

        $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/requests', [])
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'VALIDATION_ERROR')
            ->assertJsonStructure(['error' => ['details' => ['subtitle', 'description']]]);
    }

    public function test_master_teacher_can_request_mentee_removal_and_admin_can_approve(): void
    {
        $admin = $this->makeAdmin();
        $master = $this->makeTeacher(['master_teacher'], 'req-remove-master@excellenteducators.test');
        $phone = (string) (9300000000 + random_int(1000, 9999));

        $studentId = $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/students', [
            'name' => 'Remove Me Student',
            'email' => 'req-remove-student@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => $phone,
            'class_grade' => 5,
            'gender' => 'male',
        ])->assertCreated()->json('data.id');

        $this->withToken($this->tokenFor($admin))->putJson("/api/v1/admin/students/{$studentId}/mentor", [
            'teacher_id' => $master->id,
        ])->assertOk();

        $requestId = $this->withToken($this->tokenFor($master->user))->postJson('/api/v1/teacher/requests', [
            'request_type' => 'remove_mentee',
            'student_id' => $studentId,
            'reason' => 'Student moved to another city.',
        ])
            ->assertCreated()
            ->assertJsonPath('data.request_type', 'remove_mentee')
            ->assertJsonPath('data.student.id', $studentId)
            ->assertJsonPath('data.status', 'pending')
            ->json('data.id');

        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/requests/{$requestId}/resolve")
            ->assertOk()
            ->assertJsonPath('data.status', 'completed');

        $this->assertDatabaseMissing('master_teacher_assignments', [
            'student_id' => $studentId,
            'teacher_id' => $master->id,
            'ended_at' => null,
        ]);
    }

    private function makeStudent(string $email, ?User $admin = null): User
    {
        $admin ??= $this->makeAdmin();
        $phone = (string) (9100000000 + random_int(1000, 9999));
        $token = $this->tokenFor($admin);
        $studentId = $this->withHeaders(['Authorization' => 'Bearer '.$token])->postJson('/api/v1/admin/students', [
            'name' => 'Request Student',
            'email' => $email,
            'password' => 'StudentPass1!',
            'phone' => $phone,
            'class_grade' => 5,
            'gender' => 'male',
        ])->assertCreated()->json('data.id');

        return StudentProfile::query()->findOrFail($studentId)->user;
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
