<?php

namespace Tests\Feature\Api\V1;

use App\Enums\NotificationType;
use App\Enums\RoleName;
use App\Models\StudentProfile;
use App\Models\TeacherProfile;
use App\Models\User;
use App\Models\UserNotification;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class NotificationTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed([RoleSeeder::class]);
    }

    public function test_master_teacher_assignment_notifies_student_and_teacher(): void
    {
        $admin = $this->makeAdmin();
        $token = $this->tokenFor($admin);

        $studentId = $this->withToken($token)->postJson('/api/v1/admin/students', [
            'name' => 'Student One',
            'email' => 'student@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => '9000000001',
            'class_grade' => 5,
            'gender' => 'male',
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
