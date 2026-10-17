<?php

namespace Tests\Feature\Api\V1;

use App\Models\AcademicLevel;
use App\Models\Batch;
use App\Models\StudentProfile;
use Database\Seeders\LevelSeeder;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AcademicLevelBatchAllocationTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed([RoleSeeder::class, LevelSeeder::class]);
    }

    public function test_new_student_is_automatically_assigned_to_level_1_and_batch_1(): void
    {
        $admin = $this->makeAdmin();
        $token = $this->tokenFor($admin);

        $response = $this->withToken($token)->postJson('/api/v1/admin/students', [
            'name' => 'Auto Level Student',
            'email' => 'autolevel@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => '9811111111',
            'class_grade' => 6,
            'gender' => 'male',
            'address' => '123 Test Street',
        ])->assertCreated();

        $studentId = $response->json('data.id');
        $student = StudentProfile::query()->with(['academicLevel', 'activeEnrollment.batch'])->findOrFail($studentId);

        $this->assertNotNull($student->level_id);
        $this->assertEquals('Level 1', $student->academicLevel->name);
        $this->assertNotNull($student->activeEnrollment);
        $this->assertEquals('Batch 1', $student->activeEnrollment->batch->name);
        $this->assertEquals(1, $student->activeEnrollment->batch->enrolled_watermark);
        $this->assertEquals(
            'inactive',
            $student->activeEnrollment->batch->status->value
                ?? $student->activeEnrollment->batch->status,
        );
        $this->assertNull($student->currentLevelJourney);
    }

    public function test_batch_rollover_after_50_students_and_no_backfill_when_student_removed(): void
    {
        $admin = $this->makeAdmin();
        $token = $this->tokenFor($admin);

        $level1 = AcademicLevel::query()->where('name', 'Level 1')->firstOrFail();
        $batch1 = Batch::query()->where('level_id', $level1->id)->where('name', 'Batch 1')->firstOrFail();

        // Simulate 49 students already in Batch 1
        $batch1->update(['enrolled_watermark' => 49]);

        // 50th student added -> goes to Batch 1, watermark becomes 50
        $response50 = $this->withToken($token)->postJson('/api/v1/admin/students', [
            'name' => 'Student 50',
            'email' => 'student50@test.com',
            'password' => 'StudentPass1!',
            'phone' => '9800000050',
            'class_grade' => 6,
            'gender' => 'male',
        ])->assertCreated();

        $student50 = StudentProfile::query()->findOrFail($response50->json('data.id'));
        $this->assertEquals($batch1->id, $student50->activeEnrollment->batch_id);

        $batch1->refresh();
        $this->assertEquals(50, $batch1->enrolled_watermark);

        // Remove student 50 from Batch 1 -> Batch 1 now has fewer active students, but watermark stays 50
        $this->withToken($token)->deleteJson("/api/v1/admin/batches/{$batch1->id}/students/{$student50->id}")
            ->assertOk();

        $batch1->refresh();
        $this->assertEquals(50, $batch1->enrolled_watermark);

        // Now add another student (51st). Despite Batch 1 having space (watermark = 50),
        // it must NOT backfill Batch 1. Instead, Batch 2 must be auto-created!
        $response51 = $this->withToken($token)->postJson('/api/v1/admin/students', [
            'name' => 'Student 51',
            'email' => 'student51@test.com',
            'password' => 'StudentPass1!',
            'phone' => '9800000051',
            'class_grade' => 6,
            'gender' => 'male',
        ])->assertCreated();

        $student51 = StudentProfile::query()->findOrFail($response51->json('data.id'));
        $batch2 = $student51->activeEnrollment->batch;

        $this->assertNotEquals($batch1->id, $batch2->id);
        $this->assertEquals('Batch 2', $batch2->name);
        $this->assertEquals($level1->id, $batch2->level_id);
        $this->assertEquals(1, $batch2->enrolled_watermark);
    }

    public function test_inactive_batch_still_receives_students_until_full_or_admin_activates(): void
    {
        $admin = $this->makeAdmin();
        $token = $this->tokenFor($admin);

        $level1 = AcademicLevel::query()->where('name', 'Level 1')->firstOrFail();
        $batch1 = Batch::query()->where('level_id', $level1->id)->where('name', 'Batch 1')->firstOrFail();

        // Seeded / new batches start inactive — keep Batch 1 inactive for this test.
        $batch1->update(['status' => 'inactive']);
        $batch1->refresh();
        $this->assertEquals('inactive', $batch1->status->value ?? $batch1->status);

        // New student must go into inactive Batch 1 — not skip to a new Batch 2
        $response = $this->withToken($token)->postJson('/api/v1/admin/students', [
            'name' => 'Student With Inactive Batch 1',
            'email' => 'inactive_test@test.com',
            'password' => 'StudentPass1!',
            'phone' => '9800000099',
            'class_grade' => 7,
            'gender' => 'male',
        ])->assertCreated();

        $student = StudentProfile::query()->with('currentLevelJourney')->findOrFail($response->json('data.id'));
        $this->assertEquals('Batch 1', $student->activeEnrollment->batch->name);
        $this->assertNull($student->currentLevelJourney);

        // Admin activates Batch 1 → journey starts from batch starts_on
        $this->withToken($token)->patchJson("/api/v1/admin/batches/{$batch1->id}/status")
            ->assertOk()
            ->assertJsonPath('data.status', 'active');

        $student->refresh()->load('currentLevelJourney');
        $this->assertNotNull($student->currentLevelJourney);
        $batch1->refresh();
        $this->assertNotNull($batch1->starts_on);
    }

    public function test_active_batch_with_room_routes_new_students_to_new_inactive_batch(): void
    {
        $admin = $this->makeAdmin();
        $token = $this->tokenFor($admin);

        $level1 = AcademicLevel::query()->where('name', 'Level 1')->firstOrFail();
        $batch1 = Batch::query()->where('level_id', $level1->id)->where('name', 'Batch 1')->firstOrFail();

        // Admin started the cohort early — still has seats, but must not take new autos.
        $batch1->update([
            'status' => 'active',
            'starts_on' => now()->toDateString(),
            'enrolled_watermark' => 6,
        ]);

        $response = $this->withToken($token)->postJson('/api/v1/admin/students', [
            'name' => 'Post Activate Student',
            'email' => 'post.activate@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => '9800000075',
            'class_grade' => 6,
            'gender' => 'male',
        ])->assertCreated();

        $student = StudentProfile::query()->with('activeEnrollment.batch')->findOrFail($response->json('data.id'));
        $batch2 = $student->activeEnrollment->batch;

        $this->assertNotEquals($batch1->id, $batch2->id);
        $this->assertEquals('Batch 2', $batch2->name);
        $this->assertEquals('inactive', $batch2->status->value ?? $batch2->status);
        $this->assertEquals(1, $batch2->enrolled_watermark);

        $batch1->refresh();
        $this->assertEquals(6, $batch1->enrolled_watermark);
    }

    public function test_new_auto_batch_is_inactive_and_activates_when_full(): void
    {
        $admin = $this->makeAdmin();
        $token = $this->tokenFor($admin);

        $level1 = AcademicLevel::query()->where('name', 'Level 1')->firstOrFail();
        $batch1 = Batch::query()->where('level_id', $level1->id)->where('name', 'Batch 1')->firstOrFail();
        $batch1->update(['enrolled_watermark' => 50, 'status' => 'active']);

        $response = $this->withToken($token)->postJson('/api/v1/admin/students', [
            'name' => 'First In Batch 2',
            'email' => 'batch2first@test.com',
            'password' => 'StudentPass1!',
            'phone' => '9800000088',
            'class_grade' => 6,
            'gender' => 'male',
        ])->assertCreated();

        $student = StudentProfile::query()->with(['activeEnrollment.batch', 'currentLevelJourney'])
            ->findOrFail($response->json('data.id'));
        $batch2 = $student->activeEnrollment->batch;

        $this->assertEquals('Batch 2', $batch2->name);
        $this->assertEquals('inactive', $batch2->status->value ?? $batch2->status);
        $this->assertNull($student->currentLevelJourney);

        // Fill to capacity → auto-activate and start journeys
        $batch2->update(['enrolled_watermark' => 49]);
        $responseFull = $this->withToken($token)->postJson('/api/v1/admin/students', [
            'name' => 'Fills Batch 2',
            'email' => 'batch2full@test.com',
            'password' => 'StudentPass1!',
            'phone' => '9800000089',
            'class_grade' => 6,
            'gender' => 'male',
        ])->assertCreated();

        $batch2->refresh();
        $this->assertEquals(50, $batch2->enrolled_watermark);
        $this->assertEquals('active', $batch2->status->value ?? $batch2->status);

        $filled = StudentProfile::query()->with('currentLevelJourney')->findOrFail($responseFull->json('data.id'));
        $this->assertNotNull($filled->currentLevelJourney);
        $student->refresh()->load('currentLevelJourney');
        $this->assertNotNull($student->currentLevelJourney);
    }

    public function test_admin_can_manage_levels_and_level_batches(): void
    {
        $admin = $this->makeAdmin();
        $token = $this->tokenFor($admin);

        // Create Level 2
        $levelRes = $this->withToken($token)->postJson('/api/v1/admin/levels', [
            'number' => 2,
            'academic_year' => 2026,
        ])->assertCreated()
            ->assertJsonPath('data.name', 'Level 2')
            ->assertJsonPath('data.number', 2);

        $level2Id = $levelRes->json('data.id');

        // Prevent duplicate level number
        $this->withToken($token)->postJson('/api/v1/admin/levels', [
            'number' => 2,
            'academic_year' => 2026,
        ])->assertUnprocessable();

        // Add custom batch to Level 2 with year and month
        $batchRes = $this->withToken($token)->postJson("/api/v1/admin/levels/{$level2Id}/batches", [
            'name' => 'Section Alpha',
            'year' => 2026,
            'month' => 4,
        ])->assertCreated();

        $batchId = $batchRes->json('data.id');
        $this->assertEquals('Section Alpha', $batchRes->json('data.name'));
        $this->assertEquals(2026, $batchRes->json('data.year'));
        $this->assertEquals(4, $batchRes->json('data.month'));

        // Admin can edit batch name
        $this->withToken($token)->putJson("/api/v1/admin/batches/{$batchId}", [
            'name' => 'Section Alpha Renamed',
            'academic_year' => 2026,
            'year' => 2026,
            'month' => 5,
        ])->assertOk()->assertJsonPath('data.name', 'Section Alpha Renamed');
    }

    public function test_admin_levels_index_returns_levels_ordered_by_number(): void
    {
        $admin = $this->makeAdmin();
        $token = $this->tokenFor($admin);

        // Level 1 already created via seeder earlier
        $this->withToken($token)->postJson('/api/v1/admin/levels', [
            'number' => 3,
            'academic_year' => 2026,
        ])->assertCreated();

        $this->withToken($token)->postJson('/api/v1/admin/levels', [
            'number' => 2,
            'academic_year' => 2026,
        ])->assertCreated();

        $res = $this->withToken($token)->getJson('/api/v1/admin/levels')->assertOk();
        $names = array_column($res->json('data'), 'name');
        $available = $res->json('meta.available_numbers');

        $this->assertEquals(['Level 1', 'Level 2', 'Level 3'], array_slice($names, 0, 3));
        $this->assertContains(4, $available);
        $this->assertNotContains(1, $available);
        $this->assertNotContains(2, $available);
        $this->assertNotContains(3, $available);
    }

    public function test_activating_batch_starts_journey_from_activation_day_not_old_date(): void
    {
        $admin = $this->makeAdmin();
        $token = $this->tokenFor($admin);

        $level1 = AcademicLevel::query()->where('name', 'Level 1')->firstOrFail();
        $batch1 = Batch::query()->where('level_id', $level1->id)->where('name', 'Batch 1')->firstOrFail();

        // Stale starts_on (e.g. level go-live) must not drive weeks after activate.
        $batch1->update([
            'status' => 'inactive',
            'starts_on' => '2026-07-12',
        ]);

        $created = $this->withToken($token)->postJson('/api/v1/admin/students', [
            'name' => 'Week Clock Student',
            'email' => 'week.clock@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => '9800000076',
            'class_grade' => 6,
            'gender' => 'male',
        ])->assertCreated();

        $student = StudentProfile::query()->findOrFail($created->json('data.id'));

        // Pre-existing open journey with Jul 12 clock (legacy ensure / early start).
        \App\Models\StudentLevelJourney::query()->create([
            'student_id' => $student->id,
            'level_id' => $level1->id,
            'started_at' => '2026-07-12 00:00:00',
            'ended_at' => null,
        ]);

        $this->withToken($token)->patchJson("/api/v1/admin/batches/{$batch1->id}/status")
            ->assertOk()
            ->assertJsonPath('data.status', 'active');

        $batch1->refresh();
        $student->refresh()->load('currentLevelJourney');

        $this->assertSame(now()->toDateString(), $batch1->starts_on?->toDateString());
        $this->assertNotNull($student->currentLevelJourney);
        $this->assertSame(
            now()->toDateString(),
            $student->currentLevelJourney->started_at?->toDateString(),
        );
        $this->assertSame(1, $student->currentLevelJourney->weekNumberAt(now()));
    }

    public function test_deactivating_active_batch_locks_enrolled_students_out(): void
    {
        $admin = $this->makeAdmin();
        $token = $this->tokenFor($admin);

        $level1 = AcademicLevel::query()->where('name', 'Level 1')->firstOrFail();
        $batch1 = Batch::query()->where('level_id', $level1->id)->where('name', 'Batch 1')->firstOrFail();

        $created = $this->withToken($token)->postJson('/api/v1/admin/students', [
            'name' => 'Batch Pause Student',
            'email' => 'batch.pause@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => '9800000077',
            'class_grade' => 6,
            'gender' => 'female',
        ])->assertCreated();

        $student = StudentProfile::query()->with('user')->findOrFail($created->json('data.id'));

        $this->withToken($token)->patchJson("/api/v1/admin/batches/{$batch1->id}/status")
            ->assertOk()
            ->assertJsonPath('data.status', 'active');

        $student->refresh()->load(['user', 'currentLevelJourney']);
        $this->assertSame('active', $student->status->value);
        $this->assertSame('active', $student->user->status->value);
        $this->assertNotNull($student->currentLevelJourney);

        $this->withToken($token)->patchJson("/api/v1/admin/batches/{$batch1->id}/status")
            ->assertOk()
            ->assertJsonPath('data.status', 'inactive');

        $student->refresh()->load(['user', 'currentLevelJourney']);
        $this->assertSame('inactive', $student->status->value);
        $this->assertSame('inactive', $student->user->status->value);
        $this->assertNull($student->currentLevelJourney);

        $this->postJson('/api/v1/auth/login', [
            'email' => 'batch.pause@excellenteducators.test',
            'password' => 'StudentPass1!',
        ])->assertStatus(403);

        $this->withToken($token)->patchJson("/api/v1/admin/batches/{$batch1->id}/status")
            ->assertOk()
            ->assertJsonPath('data.status', 'active');

        $student->refresh()->load(['user', 'currentLevelJourney']);
        $this->assertSame('active', $student->status->value);
        $this->assertSame('active', $student->user->status->value);
        $this->assertNotNull($student->currentLevelJourney);
    }
}
