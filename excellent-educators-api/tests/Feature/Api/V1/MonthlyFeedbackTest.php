<?php

namespace Tests\Feature\Api\V1;

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
use Illuminate\Support\Carbon;
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

        $this->withToken($this->tokenFor($master->user))->postJson(
            "/api/v1/master-teacher/students/{$student->id}/feedback",
            $this->dimensionRatingPayload(4, [
                'session_date' => $sessionDate,
                'positive_points' => 'Collaborates well',
                'areas_for_improvement' => 'Speak up earlier',
            ]),
        )->assertCreated()
            ->assertJsonPath('data.month', (int) now()->format('n'))
            ->assertJsonPath('data.session_date', $sessionDate)
            ->assertJsonPath('data.positive_points', 'Collaborates well')
            ->assertJsonPath('data.discussed_in_class', 'Talked about next goals')
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

        $created = $this->withToken($token)->postJson(
            "/api/v1/master-teacher/students/{$student->id}/feedback",
            $this->payload($dimension->id, 6, $sessionDate),
        )->assertCreated();
        $bookingId = $created->json('data.session_booking_id');

        $this->withToken($token)->postJson(
            "/api/v1/master-teacher/students/{$student->id}/feedback",
            array_merge($this->payload($dimension->id, 8, $sessionDate), ['booking_id' => $bookingId]),
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

        $this->withToken($token)->putJson("/api/v1/master-teacher/students/{$student->id}/feedback/{$feedbackId}", $this->dimensionRatingPayload(5, [
            'positive_points' => 'Updated',
            'areas_for_improvement' => 'None',
        ]))->assertOk()->assertJsonPath('data.positive_points', 'Updated');

        MonthlyFeedback::query()->whereKey($feedbackId)->update([
            'year' => 2025,
            'month' => 1,
            'session_date' => '2025-01-15',
        ]);

        $this->withToken($token)->putJson("/api/v1/master-teacher/students/{$student->id}/feedback/{$feedbackId}", $this->dimensionRatingPayload(3, [
            'positive_points' => 'Too late',
            'areas_for_improvement' => 'Locked',
        ]))->assertStatus(403);

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

    public function test_reassigned_master_teacher_cannot_edit_previous_teacher_rating(): void
    {
        [$admin, $student, $master] = $this->assignedPair();
        $newMaster = $this->makeTeacher(['master_teacher'], 'new-master@excellenteducators.test');
        $token = $this->tokenFor($master->user);

        $feedbackId = $this->withToken($token)->postJson(
            "/api/v1/master-teacher/students/{$student->id}/feedback",
            $this->payload(),
        )->assertCreated()->json('data.id');

        $this->withToken($this->tokenFor($admin))->putJson("/api/v1/admin/students/{$student->id}/mentor", [
            'teacher_id' => $newMaster->id,
        ])->assertOk();

        $newToken = $this->tokenFor($newMaster->user);
        $this->withToken($newToken)->postJson(
            "/api/v1/master-teacher/students/{$student->id}/feedback",
            $this->payload(),
        )->assertStatus(409);

        $this->withToken($newToken)->putJson(
            "/api/v1/master-teacher/students/{$student->id}/feedback/{$feedbackId}",
            $this->dimensionRatingPayload(9, ['positive_points' => 'New master']),
        )->assertStatus(403);
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

        $this->withToken($adminToken)->putJson(
            "/api/v1/admin/students/{$student->id}/feedback/{$feedbackId}",
            $this->dimensionRatingPayload(9, ['positive_points' => 'Admin edit']),
        )->assertOk()->assertJsonPath('data.positive_points', 'Admin edit');

        $adminToken = $this->tokenFor($admin);
        $this->withToken($adminToken)->deleteJson("/api/v1/admin/students/{$student->id}/feedback/{$feedbackId}")
            ->assertOk();

        $this->assertDatabaseMissing('monthly_feedbacks', ['id' => $feedbackId]);

        $adminToken = $this->tokenFor($admin);
        $this->withToken($adminToken)->postJson(
            "/api/v1/admin/students/{$student->id}/feedback",
            $this->payload(7, now()->toDateString()),
        )->assertCreated();
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

        $this->assertGreaterThanOrEqual(10, count($summary));
        $this->assertTrue(collect($summary)->contains(fn ($row) => ($row['target_name'] ?? '') === 'Teamwork'));

        $studentFeedback = $this->withToken($this->tokenFor($studentUser))->getJson('/api/v1/student/feedback')->json('data.0');
        $this->assertArrayNotHasKey('discussed_in_class', $studentFeedback);

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
            ->assertJsonPath('data.feedback.total_sessions', 1)
            ->assertJsonPath('data.feedback.overall_average', 7);

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
            'gender' => 'male',
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
    private function payload(int|string $ratingOrTarget = 4, int|string|null $ratingOrDate = null, ?string $sessionDate = null): array
    {
        $rating = 4;
        $date = $sessionDate;
        if (is_int($ratingOrTarget)) {
            $rating = $ratingOrTarget;
            if (is_string($ratingOrDate)) {
                $date = $ratingOrDate;
            }
        } elseif (is_int($ratingOrDate)) {
            $rating = $ratingOrDate;
        } elseif (is_string($ratingOrDate)) {
            $date = $ratingOrDate;
        }

        return $this->dimensionRatingPayload($rating, [
            'session_date' => $date ?? AppClock::todayString(),
            'positive_points' => 'Good work',
            'areas_for_improvement' => 'Focus',
        ]);
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

    private function pastMasterClass(StudentProfile $student, TeacherProfile $teacher, ?Carbon $ends = null): SessionBooking
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
}
