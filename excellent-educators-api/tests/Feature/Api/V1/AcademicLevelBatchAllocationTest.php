<?php

namespace Tests\Feature\Api\V1;

use App\Models\AcademicLevel;
use App\Models\Batch;
use App\Models\StudentProfile;
use Database\Seeders\CareerCompassLevelSeeder;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AcademicLevelBatchAllocationTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed([RoleSeeder::class, CareerCompassLevelSeeder::class]);
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

    public function test_inactive_batch_is_skipped_and_batch_status_toggle(): void
    {
        $admin = $this->makeAdmin();
        $token = $this->tokenFor($admin);

        $level1 = AcademicLevel::query()->where('name', 'Level 1')->firstOrFail();
        $batch1 = Batch::query()->where('level_id', $level1->id)->where('name', 'Batch 1')->firstOrFail();

        // Toggle Batch 1 to inactive
        $this->withToken($token)->patchJson("/api/v1/admin/batches/{$batch1->id}/status")
            ->assertOk()
            ->assertJsonPath('data.status', 'inactive');

        $batch1->refresh();
        $this->assertEquals('inactive', $batch1->status->value ?? $batch1->status);

        // Add a student -> Batch 1 is inactive, so auto-allocator creates Batch 2
        $response = $this->withToken($token)->postJson('/api/v1/admin/students', [
            'name' => 'Student With Inactive Batch 1',
            'email' => 'inactive_test@test.com',
            'password' => 'StudentPass1!',
            'phone' => '9800000099',
            'class_grade' => 7,
            'gender' => 'male',
        ])->assertCreated();

        $student = StudentProfile::query()->findOrFail($response->json('data.id'));
        $this->assertEquals('Batch 2', $student->activeEnrollment->batch->name);

        // Admin can toggle Batch 1 back to active
        $this->withToken($token)->patchJson("/api/v1/admin/batches/{$batch1->id}/status")
            ->assertOk()
            ->assertJsonPath('data.status', 'active');
    }

    public function test_admin_can_manage_levels_and_level_batches(): void
    {
        $admin = $this->makeAdmin();
        $token = $this->tokenFor($admin);

        // Create Level 2
        $levelRes = $this->withToken($token)->postJson('/api/v1/admin/levels', [
            'name' => 'Level 2',
            'academic_year' => 2026,
        ])->assertCreated();

        $level2Id = $levelRes->json('data.id');

        // Prevent duplicate level name
        $this->withToken($token)->postJson('/api/v1/admin/levels', [
            'name' => 'Level 2',
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

    public function test_admin_levels_index_returns_levels_ordered_by_created_at_first_created_on_top(): void
    {
        $admin = $this->makeAdmin();
        $token = $this->tokenFor($admin);

        // Level 1 already created via seeder earlier
        // Create "A-New Level" which alphabetically precedes "Level 1"
        $this->withToken($token)->postJson('/api/v1/admin/levels', [
            'name' => 'A-New Level',
            'academic_year' => 2026,
        ])->assertCreated();

        // Create "Z-New Level"
        $this->withToken($token)->postJson('/api/v1/admin/levels', [
            'name' => 'Z-New Level',
            'academic_year' => 2026,
        ])->assertCreated();

        $res = $this->withToken($token)->getJson('/api/v1/admin/levels')->assertOk();
        $names = array_column($res->json('data'), 'name');

        // Verify first created is on top: Level 1 comes before A-New Level and Z-New Level
        $this->assertEquals('Level 1', $names[0]);
        $this->assertEquals('A-New Level', $names[1]);
        $this->assertEquals('Z-New Level', $names[2]);
    }
}
