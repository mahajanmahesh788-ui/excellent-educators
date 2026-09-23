<?php

namespace Tests\Feature\Api\V1;

use App\Enums\PermissionName;
use App\Enums\RoleName;
use App\Enums\UserStatus;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SubAdminTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
    }

    public function test_full_admin_creates_sub_admin_with_all_permissions_disabled(): void
    {
        $admin = $this->makeAdmin();

        $response = $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/sub-admins', [
            'name' => 'Pat Ops',
            'email' => 'sub-'.uniqid().'@excellenteducators.test',
            'password' => 'SubAdminPass1!',
            'phone' => '98'.random_int(10000000, 99999999),
            'gender' => 'female',
        ])->assertCreated();

        $permissions = $response->json('data.permissions');
        $this->assertNotEmpty($permissions);
        $this->assertContains(false, $permissions);
        $this->assertNotContains(true, $permissions);
    }

    public function test_sub_admin_cannot_list_students_until_permission_enabled(): void
    {
        $admin = $this->makeAdmin();
        $sub = $this->createSubAdminViaApi($admin);
        $token = $this->tokenFor($sub);

        $this->withToken($token)->getJson('/api/v1/admin/students')->assertForbidden();
        $this->withToken($token)->getJson('/api/v1/admin/dashboard')->assertOk();

        $this->withToken($this->tokenFor($admin))->putJson('/api/v1/admin/sub-admins/'.$sub->id, [
            'permissions' => [
                PermissionName::StudentsView->value => true,
            ],
        ])->assertOk();

        $sub->refresh();
        $this->withToken($this->tokenFor($sub))->getJson('/api/v1/admin/students')->assertOk();
        $this->withToken($this->tokenFor($sub))->postJson('/api/v1/admin/students', [
            'name' => 'Blocked',
            'email' => 'blocked-'.uniqid().'@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => '97'.random_int(10000000, 99999999),
            'class_grade' => 6,
            'gender' => 'male',
        ])->assertForbidden();
    }

    public function test_student_and_teacher_mutations_follow_toggles(): void
    {
        $admin = $this->makeAdmin();
        $student = $this->makeStudentViaAdmin($admin);
        $sub = $this->createSubAdminViaApi($admin, [
            PermissionName::StudentsView->value => true,
            PermissionName::StudentsEdit->value => true,
            PermissionName::StudentsDelete->value => true,
            PermissionName::StudentsPromote->value => true,
            PermissionName::StudentsRating->value => true,
            PermissionName::TeachersView->value => true,
            PermissionName::TeachersEdit->value => true,
            PermissionName::TeachersDelete->value => true,
            PermissionName::QueriesView->value => true,
            PermissionName::RequestsView->value => true,
        ]);

        $token = $this->tokenFor($sub);

        $this->withToken($token)->putJson('/api/v1/admin/students/'.$student->id, [
            'name' => 'Renamed Student',
        ])->assertOk();

        $this->withToken($token)->deleteJson('/api/v1/admin/students/'.$student->id)->assertOk();

        $teacher = $this->makeMasterTeacher();
        $this->withToken($token)->putJson('/api/v1/admin/teachers/'.$teacher->id, [
            'name' => 'Renamed Teacher',
        ])->assertOk();
        $this->withToken($token)->deleteJson('/api/v1/admin/teachers/'.$teacher->id)->assertOk();

        $this->withToken($token)->getJson('/api/v1/admin/attendance')->assertOk();
        $this->withToken($token)->getJson('/api/v1/admin/requests')->assertOk();
        $this->withToken($token)->getJson('/api/v1/admin/settings')->assertForbidden();
    }

    public function test_inactive_sub_admin_cannot_login(): void
    {
        $admin = $this->makeAdmin();
        $sub = $this->createSubAdminViaApi($admin);
        $email = $sub->email;

        $this->withToken($this->tokenFor($admin))->putJson('/api/v1/admin/sub-admins/'.$sub->id, [
            'status' => UserStatus::Inactive->value,
        ])->assertOk();

        $this->postJson('/api/v1/auth/login', [
            'email' => $email,
            'password' => 'SubAdminPass1!',
        ])->assertForbidden();
    }

    public function test_sub_admin_cannot_manage_sub_admins(): void
    {
        $admin = $this->makeAdmin();
        $sub = $this->createSubAdminViaApi($admin, [
            PermissionName::StudentsView->value => true,
        ]);

        $this->withToken($this->tokenFor($sub))->getJson('/api/v1/admin/sub-admins')->assertForbidden();
    }

    public function test_me_includes_permissions_for_sub_admin(): void
    {
        $admin = $this->makeAdmin();
        $sub = $this->createSubAdminViaApi($admin, [
            PermissionName::QueriesResolve->value => true,
        ]);

        $this->withToken($this->tokenFor($sub))->getJson('/api/v1/auth/me')
            ->assertOk()
            ->assertJsonPath('data.roles.0', RoleName::SubAdmin->value)
            ->assertJsonFragment([PermissionName::QueriesResolve->value]);
    }

    public function test_sub_admin_mutations_are_recorded_in_history(): void
    {
        $admin = $this->makeAdmin();
        $student = $this->makeStudentViaAdmin($admin);
        $sub = $this->createSubAdminViaApi($admin, [
            PermissionName::StudentsView->value => true,
            PermissionName::StudentsEdit->value => true,
        ]);

        $this->withToken($this->tokenFor($sub))->putJson('/api/v1/admin/students/'.$student->id, [
            'name' => 'Tracked Student',
        ])->assertOk();

        $this->withToken($this->tokenFor($admin))->getJson('/api/v1/admin/sub-admins/'.$sub->id.'/history')
            ->assertOk()
            ->assertJsonPath('data.0.type', 'student.edit')
            ->assertJsonFragment(['message' => 'Edited student Tracked Student']);
    }

    /**
     * @param  array<string, bool>  $permissions
     */
    private function createSubAdminViaApi(User $admin, array $permissions = []): User
    {
        $id = $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/sub-admins', [
            'name' => 'Sub Admin',
            'email' => 'sub-'.uniqid().'@excellenteducators.test',
            'password' => 'SubAdminPass1!',
            'phone' => '98'.random_int(10000000, 99999999),
            'gender' => 'male',
            'permissions' => $permissions,
        ])->assertCreated()->json('data.id');

        return User::query()->findOrFail($id);
    }
}
