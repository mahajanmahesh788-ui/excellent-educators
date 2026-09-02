<?php

namespace Tests\Feature\Api\V1;

use App\Enums\NotificationType;
use App\Enums\RoleName;
use App\Models\CareerCompassLevel;
use App\Models\StudentProfile;
use App\Models\TeacherProfile;
use App\Models\User;
use App\Models\UserNotification;
use Database\Seeders\CareerCompassLevelSeeder;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class NotificationTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed([RoleSeeder::class, CareerCompassLevelSeeder::class]);
    }

    public function test_master_teacher_assignment_notifies_student_and_teacher(): void
    {
        $admin = $this->makeAdmin();
        $token = $this->tokenFor($admin);
        $cc1 = CareerCompassLevel::query()->where('code', 'cc1')->firstOrFail();

        $studentId = $this->withToken($token)->postJson('/api/v1/admin/students', [
            'name' => 'Student One',
            'email' => 'student@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => '9000000001',
            'career_compass_level_id' => $cc1->id,
            'academic_year' => 2026,
        ])->json('data.id');

        $mentor = $this->makeTeacher([RoleName::MasterTeacher->value], 'mentor@excellenteducators.test');

        $this->withToken($token)->putJson("/api/v1/admin/students/{$studentId}/mentor", [
            'teacher_id' => $mentor->id,
        ])->assertOk();

        $studentUserId = StudentProfile::query()->findOrFail($studentId)->user_id;

        $this->assertDatabaseHas('user_notifications', [
            'user_id' => $studentUserId,
            'type' => NotificationType::MasterTeacherAssigned->value,
        ]);
        $this->assertDatabaseHas('user_notifications', [
            'user_id' => $mentor->user_id,
            'type' => NotificationType::MasterTeacherAssigned->value,
        ]);

        $studentUser = User::query()->findOrFail($studentUserId);
        $this->app['auth']->forgetGuards();
        $this->withToken($this->tokenFor($studentUser))
            ->getJson('/api/v1/notifications/unread-count')
            ->assertOk()
            ->assertJsonPath('data.unread_count', 1);

        $this->app['auth']->forgetGuards();
        $this->withToken($this->tokenFor($mentor->user))
            ->getJson('/api/v1/notifications/unread-count')
            ->assertOk()
            ->assertJsonPath('data.unread_count', 1);
    }

    public function test_common_teacher_assignment_notifies_teacher_and_batch_students(): void
    {
        $admin = $this->makeAdmin();
        $token = $this->tokenFor($admin);
        $cc1 = CareerCompassLevel::query()->where('code', 'cc1')->firstOrFail();

        $batchId = $this->withToken($token)->postJson('/api/v1/admin/batches', [
            'career_compass_level_id' => $cc1->id,
            'name' => 'Level 1-A',
            'academic_year' => 2026,
        ])->json('data.id');

        $studentId = $this->withToken($token)->postJson('/api/v1/admin/students', [
            'name' => 'Student One',
            'email' => 'student@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => '9000000001',
            'career_compass_level_id' => $cc1->id,
            'academic_year' => 2026,
        ])->json('data.id');

        $this->withToken($token)->postJson("/api/v1/admin/batches/{$batchId}/students", [
            'student_id' => $studentId,
        ])->assertOk();

        $common = $this->makeTeacher([RoleName::CommonTeacher->value], 'common@excellenteducators.test');

        $this->withToken($token)->postJson("/api/v1/admin/batches/{$batchId}/teacher", [
            'teacher_id' => $common->id,
        ])->assertOk();

        $studentUserId = StudentProfile::query()->findOrFail($studentId)->user_id;

        $this->assertDatabaseHas('user_notifications', [
            'user_id' => $common->user_id,
            'type' => NotificationType::CommonTeacherAssigned->value,
        ]);
        $this->assertDatabaseHas('user_notifications', [
            'user_id' => $studentUserId,
            'type' => NotificationType::CommonTeacherAssigned->value,
        ]);
    }

    public function test_user_can_list_and_mark_notifications_read(): void
    {
        $studentUser = User::factory()->create(['email' => 'student@excellenteducators.test']);
        $studentUser->assignRole(RoleName::Student->value);

        UserNotification::query()->create([
            'user_id' => $studentUser->id,
            'type' => NotificationType::MasterTeacherAssigned,
            'title' => 'Master Teacher update',
            'body' => 'Test notification.',
            'created_at' => now(),
        ]);

        $token = $this->tokenFor($studentUser);

        $list = $this->withToken($token)->getJson('/api/v1/notifications')
            ->assertOk()
            ->assertJsonCount(1, 'data');

        $notificationId = $list->json('data.0.id');

        $this->withToken($token)->patchJson("/api/v1/notifications/{$notificationId}/read")
            ->assertOk()
            ->assertJsonPath('data.read_at', fn ($value) => $value !== null);

        $this->withToken($token)->getJson('/api/v1/notifications/unread-count')
            ->assertOk()
            ->assertJsonPath('data.unread_count', 0);
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
