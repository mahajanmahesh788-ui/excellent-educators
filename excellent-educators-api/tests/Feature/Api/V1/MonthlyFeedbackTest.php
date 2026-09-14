<?php

namespace Tests\Feature\Api\V1;

use App\Enums\RoleName;
use App\Enums\SessionBookingStatus;
use App\Enums\SessionBookingType;
use App\Models\Dimension;
use App\Models\MonthlyFeedback;
use App\Models\SessionBooking;
use App\Models\StudentProfile;
use App\Models\TeacherProfile;
use App\Models\User;
use App\Support\AppClock;
use Database\Seeders\DimensionSeeder;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\PermissionRegistrar;
use Tests\TestCase;

class MonthlyFeedbackTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed([RoleSeeder::class, DimensionSeeder::class]);
    }

    public function test_master_teacher_can_view_assigned_students_and_create_feedback(): void
    {
        [$admin, $student, $master] = $this->assignedPair();
        $dimension = Dimension::query()->where('code', 'TW')->firstOrFail();

        $this->withToken($this->tokenFor($master->user))->getJson('/api/v1/master-teacher/students')
            ->assertOk()
            ->assertJsonPath('data.0.id', $student->id)
            ->assertJsonPath('data.0.feedback.can_rate', true)
            ->assertJsonPath('data.0.feedback.can_edit_rating', false);

        $this->withToken($this->tokenFor($master->user))->getJson("/api/v1/master-teacher/students/{$student->id}")
            ->assertOk()
            ->assertJsonPath('data.feedback.can_rate', true);

        $sessionDate = now()->toDateString();

        $this->withToken($this->tokenFor($master->user))->postJson("/api/v1/master-teacher/students/{$student->id}/feedback", [
            'session_date' => $sessionDate,
            'items' => [[
                'target_type' => 'dimension',
                'target_id' => $dimension->id,
                'rating' => 4,
                'positive_points' => 'Collaborates well',
                'areas_for_improvement' => 'Speak up earlier',
                'recommended_next_action' => 'Lead a pair activity',
            ]],
        ])->assertCreated()
            ->assertJsonPath('data.month', (int) now()->format('n'))
            ->assertJsonPath('data.session_date', $sessionDate)
            ->assertJsonPath('data.items.0.target_name', 'Teamwork')
            ->assertJsonPath('data.editable', true);

        $this->assertDatabaseHas('audit_logs', ['action' => 'feedback.created']);
    }

    public function test_unassigned_master_teacher_cannot_create_feedback(): void
    {
        [$admin, $student] = $this->assignedPair();
        $other = $this->makeTeacher(['master_teacher'], 'other-master@excellenteducators.test');
        $dimension = Dimension::query()->firstOrFail();

        $this->withToken($this->tokenFor($other->user))->postJson("/api/v1/master-teacher/students/{$student->id}/feedback", $this->payload($dimension->id))
            ->assertStatus(403);
    }

    public function test_duplicate_monthly_rating_is_rejected(): void
    {
        [$admin, $student, $master] = $this->assignedPair();
        $dimension = Dimension::query()->firstOrFail();
        $token = $this->tokenFor($master->user);
        $sessionDate = now()->toDateString();

        $this->withToken($token)->postJson(
            "/api/v1/master-teacher/students/{$student->id}/feedback",
            $this->payload($dimension->id, 6, $sessionDate),
        )->assertCreated();

        $this->withToken($token)->postJson(
            "/api/v1/master-teacher/students/{$student->id}/feedback",
            $this->payload($dimension->id, 8, $sessionDate),
        )->assertStatus(409)
            ->assertJsonPath('error.code', 'FEEDBACK_DUPLICATE');

        $this->assertSame(1, MonthlyFeedback::query()->where('student_id', $student->id)->count());
    }

    public function test_master_teacher_can_filter_students_by_month_and_rated_status(): void
    {
        [$admin, $student, $master] = $this->assignedPair();
        $dimension = Dimension::query()->firstOrFail();
        $token = $this->tokenFor($master->user);

        $this->pastMasterClass($student, $master, AppClock::now()->setDate(2026, 8, 15)->setTime(11, 0));

        $this->withToken($token)->postJson(
            "/api/v1/master-teacher/students/{$student->id}/feedback",
            $this->payload($dimension->id, 6, '2026-08-15'),
        )->assertCreated();

        $this->withToken($token)->getJson('/api/v1/master-teacher/students?year=2026&month=8&rated=1')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $student->id)
            ->assertJsonPath('data.0.feedback.filter_year', 2026)
            ->assertJsonPath('data.0.feedback.filter_month', 8)
            ->assertJsonPath('data.0.feedback.filter_month_completed', true);

        $this->withToken($token)->getJson('/api/v1/master-teacher/students?year=2026&month=8&rated=0')
            ->assertOk()
            ->assertJsonCount(0, 'data');

        $this->withToken($token)->getJson('/api/v1/master-teacher/students?year=2026&month=9&rated=0')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.feedback.filter_month_completed', false);
    }

    public function test_rating_outside_range_is_rejected(): void
    {
        [$admin, $student, $master] = $this->assignedPair();
        $dimension = Dimension::query()->firstOrFail();

        $this->withToken($this->tokenFor($master->user))->postJson(
            "/api/v1/master-teacher/students/{$student->id}/feedback",
            $this->payload($dimension->id, 11),
        )->assertStatus(422);
    }

    public function test_master_teacher_can_submit_rating_up_to_ten(): void
    {
        [$admin, $student, $master] = $this->assignedPair();
        $dimension = Dimension::query()->firstOrFail();

        $this->withToken($this->tokenFor($master->user))->postJson(
            "/api/v1/master-teacher/students/{$student->id}/feedback",
            $this->payload($dimension->id, 10),
        )->assertCreated()
            ->assertJsonPath('data.items.0.rating', 10);
    }

    public function test_master_teacher_can_edit_and_delete_during_rating_month_only(): void
    {
        [$admin, $student, $master] = $this->assignedPair();
        $dimension = Dimension::query()->firstOrFail();
        $token = $this->tokenFor($master->user);
        $sessionDate = now()->toDateString();

        $feedbackId = $this->withToken($token)->postJson(
            "/api/v1/master-teacher/students/{$student->id}/feedback",
            $this->payload($dimension->id, sessionDate: $sessionDate),
        )->assertCreated()->json('data.id');

        $this->withToken($token)->putJson("/api/v1/master-teacher/students/{$student->id}/feedback/{$feedbackId}", [
            'items' => [[
                'target_type' => 'dimension',
                'target_id' => $dimension->id,
                'rating' => 5,
                'positive_points' => 'Updated',
                'areas_for_improvement' => 'None',
                'recommended_next_action' => 'Keep going',
            ]],
        ])->assertOk()->assertJsonPath('data.items.0.rating', 5);

        MonthlyFeedback::query()->whereKey($feedbackId)->update([
            'year' => 2025,
            'month' => 1,
            'session_date' => '2025-01-15',
        ]);

        $this->withToken($token)->putJson("/api/v1/master-teacher/students/{$student->id}/feedback/{$feedbackId}", [
            'items' => [[
                'target_type' => 'dimension',
                'target_id' => $dimension->id,
                'rating' => 3,
                'positive_points' => 'Too late',
                'areas_for_improvement' => 'Locked',
                'recommended_next_action' => 'Stop',
            ]],
        ])->assertStatus(403);

        $this->withToken($token)->deleteJson("/api/v1/master-teacher/students/{$student->id}/feedback/{$feedbackId}")
            ->assertStatus(403);
    }

    public function test_master_teacher_can_delete_own_rating_during_rating_month(): void
    {
        [$admin, $student, $master] = $this->assignedPair();
        $dimension = Dimension::query()->firstOrFail();
        $token = $this->tokenFor($master->user);

        $feedbackId = $this->withToken($token)->postJson(
            "/api/v1/master-teacher/students/{$student->id}/feedback",
            $this->payload($dimension->id, sessionDate: now()->toDateString()),
        )->assertCreated()->json('data.id');

        $this->withToken($token)->deleteJson("/api/v1/master-teacher/students/{$student->id}/feedback/{$feedbackId}")
            ->assertOk();

        $this->assertDatabaseMissing('monthly_feedbacks', ['id' => $feedbackId]);
    }

    public function test_reassigned_master_teacher_cannot_edit_or_add_when_month_already_rated(): void
    {
        [$admin, $student, $master] = $this->assignedPair();
        $newMaster = $this->makeTeacher(['master_teacher'], 'new-master@excellenteducators.test');
        $dimension = Dimension::query()->firstOrFail();
        $token = $this->tokenFor($master->user);
        $sessionDate = now()->toDateString();

        $feedbackId = $this->withToken($token)->postJson(
            "/api/v1/master-teacher/students/{$student->id}/feedback",
            $this->payload($dimension->id, sessionDate: $sessionDate),
        )->assertCreated()->json('data.id');

        $this->withToken($this->tokenFor($admin))->putJson("/api/v1/admin/students/{$student->id}/mentor", [
            'teacher_id' => $newMaster->id,
        ])->assertOk();

        $this->withToken($token)->putJson("/api/v1/master-teacher/students/{$student->id}/feedback/{$feedbackId}", [
            'items' => [[
                'target_type' => 'dimension',
                'target_id' => $dimension->id,
                'rating' => 2,
                'positive_points' => 'Old master',
                'areas_for_improvement' => 'No',
                'recommended_next_action' => 'No',
            ]],
        ])->assertStatus(403);

        $this->withToken($token)->deleteJson("/api/v1/master-teacher/students/{$student->id}/feedback/{$feedbackId}")
            ->assertStatus(403);

        $newToken = $this->tokenFor($newMaster->user);
        $this->withToken($newToken)->postJson(
            "/api/v1/master-teacher/students/{$student->id}/feedback",
            $this->payload($dimension->id, sessionDate: $sessionDate),
        )->assertStatus(409);

        $this->withToken($newToken)->putJson("/api/v1/master-teacher/students/{$student->id}/feedback/{$feedbackId}", [
            'items' => [[
                'target_type' => 'dimension',
                'target_id' => $dimension->id,
                'rating' => 9,
                'positive_points' => 'New master',
                'areas_for_improvement' => 'No',
                'recommended_next_action' => 'No',
            ]],
        ])->assertStatus(403);
    }

    public function test_new_master_teacher_can_rate_when_previous_master_did_not(): void
    {
        [$admin, $student, $master] = $this->assignedPair();
        $newMaster = $this->makeTeacher(['master_teacher'], 'fresh-master@excellenteducators.test');
        $dimension = Dimension::query()->firstOrFail();

        $this->withToken($this->tokenFor($admin))->putJson("/api/v1/admin/students/{$student->id}/mentor", [
            'teacher_id' => $newMaster->id,
        ])->assertOk();

        $this->pastMasterClass($student, $newMaster);

        $this->withToken($this->tokenFor($newMaster->user))->postJson(
            "/api/v1/master-teacher/students/{$student->id}/feedback",
            $this->payload($dimension->id, sessionDate: now()->toDateString()),
        )->assertCreated();
    }

    public function test_admin_can_manage_feedback_anytime(): void
    {
        [$admin, $student, $master] = $this->assignedPair();
        $dimension = Dimension::query()->firstOrFail();
        $this->pastMasterClass($student, $master, AppClock::now()->setDate(2025, 1, 15)->setTime(11, 0));

        $feedbackId = $this->withToken($this->tokenFor($master->user))->postJson(
            "/api/v1/master-teacher/students/{$student->id}/feedback",
            $this->payload($dimension->id, sessionDate: '2025-01-15'),
        )->assertCreated()->json('data.id');

        $adminToken = $this->tokenFor($admin);

        $this->withToken($adminToken)->putJson("/api/v1/admin/students/{$student->id}/feedback/{$feedbackId}", [
            'items' => [[
                'target_type' => 'dimension',
                'target_id' => $dimension->id,
                'rating' => 9,
                'positive_points' => 'Admin edit',
                'areas_for_improvement' => 'None',
                'recommended_next_action' => 'Continue',
            ]],
        ])->assertOk()->assertJsonPath('data.items.0.rating', 9);

        $adminToken = $this->tokenFor($admin);
        $this->withToken($adminToken)->deleteJson("/api/v1/admin/students/{$student->id}/feedback/{$feedbackId}")
            ->assertOk();

        $this->assertDatabaseMissing('monthly_feedbacks', ['id' => $feedbackId]);

        $adminToken = $this->tokenFor($admin);
        $this->withToken($adminToken)->postJson("/api/v1/admin/students/{$student->id}/feedback", [
            'session_date' => now()->toDateString(),
            'items' => [[
                'target_type' => 'dimension',
                'target_id' => $dimension->id,
                'rating' => 7,
                'positive_points' => 'Admin create',
                'areas_for_improvement' => 'None',
                'recommended_next_action' => 'Continue',
            ]],
        ])->assertCreated();
    }

    public function test_common_teacher_cannot_create_feedback(): void
    {
        [$admin, $student] = $this->assignedPair();
        $common = $this->makeTeacher(['common_teacher'], 'common-fb@excellenteducators.test');
        $dimension = Dimension::query()->firstOrFail();

        $this->withToken($this->tokenFor($common->user))->postJson(
            "/api/v1/master-teacher/students/{$student->id}/feedback",
            $this->payload($dimension->id),
        )->assertStatus(403);
    }

    public function test_student_can_view_own_feedback_summary(): void
    {
        [$admin, $student, $master] = $this->assignedPair();
        $dimension = Dimension::query()->where('code', 'TW')->firstOrFail();
        $token = $this->tokenFor($master->user);
        $sessionDate = now()->toDateString();

        $this->withToken($token)->postJson(
            "/api/v1/master-teacher/students/{$student->id}/feedback",
            $this->payload($dimension->id, 6, $sessionDate),
        )->assertCreated();

        $this->pastMasterClass($student, $master, AppClock::now()->setDate(2026, 8, 18)->setTime(11, 0));
        $this->withToken($token)->postJson(
            "/api/v1/master-teacher/students/{$student->id}/feedback",
            $this->payload($dimension->id, 8, '2026-08-18'),
        )->assertCreated();

        $studentUser = $student->user;
        $this->withToken($this->tokenFor($studentUser))->getJson('/api/v1/student/feedback')
            ->assertOk()
            ->assertJsonPath('data.0.master_teacher.full_name', $master->full_name);

        $summary = $this->withToken($this->tokenFor($studentUser))->getJson('/api/v1/student/feedback/summary')
            ->assertOk()
            ->assertJsonPath('data.total_sessions', 2)
            ->assertJsonPath('data.overall_average', 7)
            ->json('data.by_dimension');

        $this->assertSame('Teamwork', collect($summary)->value('target_name'));

        $this->withToken($this->tokenFor($studentUser))->postJson(
            "/api/v1/master-teacher/students/{$student->id}/feedback",
            $this->payload($dimension->id, 3, '2026-09-01'),
        )->assertStatus(403);
    }

    public function test_admin_can_view_student_feedback_summary_and_list(): void
    {
        [$admin, $student, $master] = $this->assignedPair();
        $dimension = Dimension::query()->where('code', 'TW')->firstOrFail();

        $this->withToken($this->tokenFor($master->user))->postJson(
            "/api/v1/master-teacher/students/{$student->id}/feedback",
            $this->payload($dimension->id, 7, now()->toDateString()),
        )->assertCreated();

        $this->withToken($this->tokenFor($admin))->getJson("/api/v1/admin/students/{$student->id}")
            ->assertOk()
            ->assertJsonPath('data.feedback.current_month_completed', true)
            ->assertJsonPath('data.feedback.total_sessions', 1);

        $this->withToken($this->tokenFor($admin))->getJson("/api/v1/admin/students/{$student->id}/feedback/summary")
            ->assertOk()
            ->assertJsonPath('data.total_sessions', 1)
            ->assertJsonPath('data.overall_average', 7);

        $this->withToken($this->tokenFor($admin))->getJson("/api/v1/admin/students/{$student->id}/feedback")
            ->assertOk()
            ->assertJsonPath('data.0.session_date', now()->toDateString());
    }

    /**
     * @return array{0: User, 1: StudentProfile, 2: TeacherProfile}
     */
    private function assignedPair(): array
    {
        $admin = $this->makeAdmin();
        $studentId = $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/students', [
            'name' => 'Feedback Student',
            'email' => 'fb-student@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => '9111111111',
            'class_grade' => 5,
        ])->assertCreated()->json('data.id');

        $master = $this->makeTeacher(['master_teacher'], 'fb-master@excellenteducators.test');
        $this->withToken($this->tokenFor($admin))->putJson("/api/v1/admin/students/{$studentId}/mentor", [
            'teacher_id' => $master->id,
        ])->assertOk();

        $student = StudentProfile::query()->findOrFail($studentId);
        $this->pastMasterClass($student, $master);

        return [$admin, $student, $master];
    }

    /**
     * @return array<string, mixed>
     */
    private function payload(string $targetId, int $rating = 4, ?string $sessionDate = null): array
    {
        return [
            'session_date' => $sessionDate ?? AppClock::todayString(),
            'items' => [[
                'target_type' => 'dimension',
                'target_id' => $targetId,
                'rating' => $rating,
                'positive_points' => 'Good work',
                'areas_for_improvement' => 'Focus',
                'recommended_next_action' => 'Practice',
            ]],
        ];
    }

    private function makeAdmin(): User
    {
        $user = User::factory()->create(['email' => 'ops-feedback@excellenteducators.test']);
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

    private function pastMasterClass(StudentProfile $student, TeacherProfile $teacher, ?\Illuminate\Support\Carbon $ends = null): SessionBooking
    {
        $endsAt = $ends ?? AppClock::now()->subHour();
        $startsAt = $endsAt->copy()->subHour();

        return SessionBooking::query()->create([
            'student_id' => $student->id,
            'teacher_id' => $teacher->id,
            'type' => SessionBookingType::MasterClass->value,
            'date' => $startsAt->toDateString(),
            'starts_at' => $startsAt,
            'ends_at' => $endsAt,
            'status' => SessionBookingStatus::Completed->value,
        ]);
    }

    private function tokenFor(User $user): string
    {
        $this->app['auth']->forgetGuards();
        app(PermissionRegistrar::class)->forgetCachedPermissions();

        return $user->fresh()->createToken('test')->plainTextToken;
    }
}
