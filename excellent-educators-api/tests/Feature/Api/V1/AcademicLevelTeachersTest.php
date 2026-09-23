<?php

namespace Tests\Feature\Api\V1;

use App\Enums\RoleName;
use App\Models\AcademicLevel;
use App\Models\User;
use Database\Seeders\CareerCompassLevelSeeder;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AcademicLevelTeachersTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed([RoleSeeder::class, CareerCompassLevelSeeder::class]);
    }

    public function test_admin_can_assign_multiple_master_teachers_to_a_level(): void
    {
        $admin = $this->makeAdmin();
        $token = $this->tokenFor($admin);

        $level = AcademicLevel::query()->where('name', 'Level 1')->firstOrFail();

        $mt1 = $this->makeMasterTeacher('Master Teacher One', 'mt1@excellenteducators.test');
        $mt2 = $this->makeMasterTeacher('Master Teacher Two', 'mt2@excellenteducators.test');

        // Assign teacher 1
        $res1 = $this->withToken($token)->postJson("/api/v1/admin/levels/{$level->id}/teachers", [
            'teacher_id' => $mt1->id,
        ])->assertOk();

        $this->assertCount(1, $res1->json('data.master_teachers'));
        $this->assertEquals($mt1->id, $res1->json('data.master_teachers.0.id'));

        // Assign teacher 2
        $res2 = $this->withToken($token)->postJson("/api/v1/admin/levels/{$level->id}/teachers", [
            'teacher_id' => $mt2->id,
        ])->assertOk();

        $this->assertCount(2, $res2->json('data.master_teachers'));

        // Check level show returns both teachers
        $showRes = $this->withToken($token)->getJson("/api/v1/admin/levels/{$level->id}")->assertOk();
        $this->assertCount(2, $showRes->json('data.master_teachers'));

        // Check unassign teacher 1
        $delRes = $this->withToken($token)->deleteJson("/api/v1/admin/levels/{$level->id}/teachers/{$mt1->id}")->assertOk();
        $this->assertCount(1, $delRes->json('data.master_teachers'));
        $this->assertEquals($mt2->id, $delRes->json('data.master_teachers.0.id'));
    }

    public function test_student_in_level_sees_all_assigned_master_teachers(): void
    {
        $admin = $this->makeAdmin();
        $adminToken = $this->tokenFor($admin);

        $level = AcademicLevel::query()->where('name', 'Level 1')->firstOrFail();
        $mt1 = $this->makeMasterTeacher('Master Teacher Alpha', 'mtalpha@excellenteducators.test');
        $mt2 = $this->makeMasterTeacher('Master Teacher Beta', 'mtbeta@excellenteducators.test');

        // Assign both to Level 1
        $this->withToken($adminToken)->postJson("/api/v1/admin/levels/{$level->id}/teachers", [
            'teacher_id' => $mt1->id,
        ])->assertOk();
        $this->withToken($adminToken)->postJson("/api/v1/admin/levels/{$level->id}/teachers", [
            'teacher_id' => $mt2->id,
        ])->assertOk();

        // Create student (auto placed in Level 1)
        $studentPass = 'Pass1234!';
        $studentUser = User::factory()->create([
            'email' => 'levelstudent@excellenteducators.test',
            'password' => bcrypt($studentPass),
        ]);
        $studentUser->assignRole(RoleName::Student->value);

        $this->withToken($adminToken)->postJson('/api/v1/admin/students', [
            'name' => 'Level Student',
            'email' => 'newstudentlevel@excellenteducators.test',
            'password' => $studentPass,
            'phone' => '9988776655',
            'class_grade' => 6,
            'gender' => 'male',
        ])->assertCreated();

        $newStudentUser = User::query()->where('email', 'newstudentlevel@excellenteducators.test')->firstOrFail();
        $this->app['auth']->forgetGuards();
        $studentToken = $this->tokenFor($newStudentUser);

        // Fetch student profile as student
        $profileRes = $this->withToken($studentToken)->getJson('/api/v1/student/profile')->assertOk();

        $masterTeachers = $profileRes->json('data.master_teachers');
        $this->assertCount(2, $masterTeachers);
        $teacherIds = array_column($masterTeachers, 'id');
        $this->assertContains($mt1->id, $teacherIds);
        $this->assertContains($mt2->id, $teacherIds);
    }

    public function test_teacher_index_can_exclude_teachers_already_assigned_to_level(): void
    {
        $admin = $this->makeAdmin();
        $adminToken = $this->tokenFor($admin);

        $level = AcademicLevel::query()->where('name', 'Level 1')->firstOrFail();
        $mt1 = $this->makeMasterTeacher('Assigned Teacher', 'assigned@excellenteducators.test');
        $mt2 = $this->makeMasterTeacher('Unassigned Teacher', 'unassigned@excellenteducators.test');

        // Assign mt1 to Level 1
        $this->withToken($adminToken)->postJson("/api/v1/admin/levels/{$level->id}/teachers", [
            'teacher_id' => $mt1->id,
        ])->assertOk();

        // Query teachers excluding Level 1
        $res = $this->withToken($adminToken)->getJson("/api/v1/admin/teachers?exclude_level_id={$level->id}")->assertOk();
        $teachers = $res->json('data');
        $teacherIds = array_column($teachers, 'id');

        $this->assertNotContains($mt1->id, $teacherIds);
        $this->assertContains($mt2->id, $teacherIds);
    }

    public function test_master_teacher_lists_students_from_assigned_level_and_batch(): void
    {
        $admin = $this->makeAdmin();
        $adminToken = $this->tokenFor($admin);
        $level = AcademicLevel::query()->where('name', 'Level 1')->firstOrFail();
        $teacher = $this->makeMasterTeacher('Roster Teacher', 'roster@excellenteducators.test');

        $this->withToken($adminToken)->postJson("/api/v1/admin/levels/{$level->id}/teachers", [
            'teacher_id' => $teacher->id,
        ])->assertOk();

        $studentId = $this->withToken($adminToken)->postJson('/api/v1/admin/students', [
            'name' => 'Level Student',
            'email' => 'level-student@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => '9812345678',
            'class_grade' => 6,
            'gender' => 'male',
        ])->assertCreated()->json('data.id');

        $this->app['auth']->forgetGuards();
        $list = $this->withToken($this->tokenFor($teacher->user))
            ->getJson('/api/v1/master-teacher/students')
            ->assertOk()
            ->json();

        $this->assertSame($studentId, $list['data'][0]['id']);
        $this->assertSame('Level 1', $list['data'][0]['level']['name']);
        $this->assertNotEmpty($list['data'][0]['batch']['name']);
        $this->assertNotEmpty($list['meta']['levels']);
        $this->assertSame($level->id, $list['meta']['levels'][0]['id']);
    }
}
