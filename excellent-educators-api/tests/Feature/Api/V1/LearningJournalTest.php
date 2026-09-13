<?php

namespace Tests\Feature\Api\V1;

use App\Enums\RoleName;
use App\Models\AcademicLevel;
use App\Models\StudentProfile;
use App\Models\TeacherProfile;
use App\Models\User;
use App\Models\WeeklyAssignmentAttempt;
use Database\Seeders\CareerCompassLevelSeeder;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Tests\TestCase;

class LearningJournalTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed([RoleSeeder::class, CareerCompassLevelSeeder::class]);
        Carbon::setTestNow(Carbon::parse('2026-07-15 10:00:00', 'Asia/Kolkata'));
    }

    public function test_july_join_starts_level_one_week_one_not_july_content(): void
    {
        [$admin, $student] = $this->makeStudent();
        $level1 = AcademicLevel::query()->where('name', 'Level 1')->firstOrFail();
        $this->seedWeek($admin, $level1, 1, 'https://video.test/l1w1');
        $this->seedWeek($admin, $level1, 27, 'https://video.test/l1w27');

        $dashboard = $this->withToken($this->tokenFor($student->user))
            ->getJson('/api/v1/student/learning/dashboard')
            ->assertOk()
            ->json('data');

        $this->assertSame(1, $dashboard['current_week']);
        $this->assertSame('https://video.test/l1w1', $dashboard['week']['video_url']);
        $this->assertArrayNotHasKey('month', $dashboard['week']);
        $this->assertArrayNotHasKey('year', $dashboard['week']);
        $this->assertArrayNotHasKey('rating', $dashboard['week']);

        $staffWeek = $this->withToken($this->tokenFor($admin))
            ->getJson("/api/v1/admin/students/{$student->id}/learning-journal")
            ->assertOk()
            ->json('data.levels.0.weeks.0');

        $this->assertSame(1, $staffWeek['week_number']);
        $this->assertSame('January', $staffWeek['month']);
        $this->assertSame(2026, $staffWeek['year']);
        $this->assertSame('2026-07-15', $staffWeek['study_date']);
    }

    public function test_each_level_has_its_own_week_one_and_promotion_preserves_history(): void
    {
        [$admin, $student] = $this->makeStudent();
        $level1 = AcademicLevel::query()->where('name', 'Level 1')->firstOrFail();
        $level2 = AcademicLevel::query()->create([
            'name' => 'Level 2',
            'academic_year' => 2026,
            'status' => 'active',
        ]);
        $week1 = $this->seedWeek($admin, $level1, 1, 'https://video.test/l1w1');
        $this->seedWeek($admin, $level2, 1, 'https://video.test/l2w1');

        $this->submitAttempt($student, 1, $week1, 0);

        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/students/{$student->id}/promote", [
            'level_id' => $level2->id,
        ])->assertOk();

        $journal = $this->withToken($this->tokenFor($student->user))
            ->getJson('/api/v1/student/learning/journal')
            ->assertOk()
            ->json('data');

        $this->assertCount(2, $journal['levels']);
        $this->assertFalse($journal['levels'][0]['is_current']);
        $this->assertTrue($journal['levels'][1]['is_current']);
        $this->assertSame(1, $journal['levels'][0]['weeks'][0]['week_number']);
        $this->assertSame('completed', $journal['levels'][0]['weeks'][0]['assignment_status']);
        $this->assertSame('https://video.test/l1w1', $journal['levels'][0]['weeks'][0]['video_url']);
        $this->assertSame(1, $journal['levels'][0]['weeks'][0]['score']['correct']);
        $this->assertSame(2, $journal['levels'][0]['weeks'][0]['score']['total']);
        $this->assertSame(50, $journal['levels'][0]['weeks'][0]['score']['percentage']);
        $this->assertSame(1, $journal['levels'][1]['weeks'][0]['week_number']);
        $this->assertSame('pending', $journal['levels'][1]['weeks'][0]['assignment_status']);
        $this->assertNull($journal['levels'][1]['weeks'][0]['score']);

        $dashboard = $this->withToken($this->tokenFor($student->user))
            ->getJson('/api/v1/student/learning/dashboard')
            ->assertOk()
            ->json('data');

        $this->assertSame($level2->id, $dashboard['current_level']['id']);
        $this->assertSame(1, $dashboard['current_week']);
        $this->assertSame('https://video.test/l2w1', $dashboard['week']['video_url']);
    }

    public function test_two_attempts_are_stored_and_third_is_rejected(): void
    {
        [$admin, $student] = $this->makeStudent();
        $level1 = AcademicLevel::query()->where('name', 'Level 1')->firstOrFail();
        $unit = $this->seedWeek($admin, $level1, 1, 'https://video.test/l1w1');

        $this->submitAttempt($student, 1, $unit, 0)->assertCreated();
        $this->submitAttempt($student, 1, $unit, 1)->assertCreated();
        $this->submitAttempt($student, 1, $unit, 0)
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'ATTEMPT_LIMIT');

        $this->assertSame(2, WeeklyAssignmentAttempt::query()->where('student_id', $student->id)->count());
        $this->assertEqualsCanonicalizing(
            [1, 2],
            WeeklyAssignmentAttempt::query()->where('student_id', $student->id)->pluck('attempt_number')->all(),
        );

        $detail = $this->withToken($this->tokenFor($student->user))
            ->getJson('/api/v1/student/learning/journal')
            ->assertOk()
            ->json('data.levels.0.weeks.0');

        $journeyId = $detail['journey_id'];
        $week = $this->withToken($this->tokenFor($student->user))
            ->getJson("/api/v1/student/learning/journal/{$journeyId}/1")
            ->assertOk()
            ->json('data');

        $this->assertCount(2, $week['attempts']);
        $this->assertFalse($week['can_submit']);
        $this->assertSame(2, $week['attempts_used']);
        $this->assertArrayNotHasKey('rating', $week);
        $this->assertArrayNotHasKey('month', $week);
    }

    public function test_historical_video_survives_content_update(): void
    {
        [$admin, $student] = $this->makeStudent();
        $level1 = AcademicLevel::query()->where('name', 'Level 1')->firstOrFail();
        $unit = $this->seedWeek($admin, $level1, 1, 'https://video.test/original');
        $this->submitAttempt($student, 1, $unit, 0)->assertCreated();

        $this->seedWeek($admin, $level1, 1, 'https://video.test/replaced');

        $journal = $this->withToken($this->tokenFor($student->user))
            ->getJson('/api/v1/student/learning/journal')
            ->assertOk()
            ->json('data.levels.0.weeks.0');

        $this->assertSame('https://video.test/original', $journal['video_url']);
    }

    public function test_student_cannot_view_another_journal_or_modify_teacher_rating(): void
    {
        [$admin, $student] = $this->makeStudent();
        $other = $this->makeStudent()[1];
        $level1 = AcademicLevel::query()->where('name', 'Level 1')->firstOrFail();
        $this->seedWeek($admin, $level1, 1, 'https://video.test/l1w1');

        $this->withToken($this->tokenFor($other->user))
            ->getJson("/api/v1/admin/students/{$student->id}/learning-journal")
            ->assertForbidden();

        $this->withToken($this->tokenFor($student->user))
            ->postJson("/api/v1/admin/students/{$student->id}/promote", [
                'level_id' => $level1->id,
            ])
            ->assertForbidden();
    }

    public function test_master_teacher_can_view_staff_fields_for_permitted_student(): void
    {
        [$admin, $student] = $this->makeStudent();
        $level1 = AcademicLevel::query()->where('name', 'Level 1')->firstOrFail();
        $this->seedWeek($admin, $level1, 1, 'https://video.test/l1w1');
        $teacher = $this->makeMasterTeacher($level1);

        $journal = $this->withToken($this->tokenFor($teacher->user))
            ->getJson("/api/v1/master-teacher/students/{$student->id}/learning-journal")
            ->assertOk()
            ->json('data');

        $this->assertSame($student->full_name, $journal['student']['full_name']);
        $this->assertSame('January', $journal['levels'][0]['weeks'][0]['month']);
        $this->assertArrayNotHasKey('rating', $journal['levels'][0]['weeks'][0]);
    }

    /**
     * @return array{0: User, 1: StudentProfile}
     */
    private function makeStudent(): array
    {
        $admin = $this->makeAdmin();
        $id = $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/students', [
            'name' => 'Journal Student '.uniqid(),
            'email' => 'journal-'.uniqid().'@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => '98'.random_int(10000000, 99999999),
            'class_grade' => 6,
        ])->assertCreated()->json('data.id');

        return [$admin, StudentProfile::query()->with('user')->findOrFail($id)];
    }

    private function seedWeek(User $admin, AcademicLevel $level, int $week, string $videoUrl): array
    {
        $payload = $this->withToken($this->tokenFor($admin))->putJson("/api/v1/admin/levels/{$level->id}/weekly-learnings", [
            'week_number' => $week,
            'video_url' => $videoUrl,
            'questions' => [
                [
                    'question_text' => 'Question 1',
                    'options' => [
                        ['option_text' => 'A', 'is_correct' => true],
                        ['option_text' => 'B', 'is_correct' => false],
                    ],
                ],
                [
                    'question_text' => 'Question 2',
                    'options' => [
                        ['option_text' => 'C', 'is_correct' => false],
                        ['option_text' => 'D', 'is_correct' => true],
                    ],
                ],
            ],
        ])->assertOk()->json('data');

        return $payload;
    }

    private function submitAttempt(StudentProfile $student, int $week, array $unit, int $optionIndex)
    {
        $journal = $this->withToken($this->tokenFor($student->user))
            ->getJson('/api/v1/student/learning/journal')
            ->assertOk()
            ->json('data.levels.0');

        $answers = [];
        foreach ($unit['questions'] as $question) {
            $answers[] = [
                'question_id' => $question['id'],
                'option_id' => $question['options'][$optionIndex]['id'],
            ];
        }

        return $this->withToken($this->tokenFor($student->user))
            ->postJson("/api/v1/student/learning/journal/{$journal['journey_id']}/{$week}", [
                'answers' => $answers,
            ]);
    }

    private function makeAdmin(): User
    {
        $user = User::factory()->create(['email' => 'ops-learn-'.uniqid().'@excellenteducators.test']);
        $user->assignRole(RoleName::OperationalAdmin->value);

        return $user;
    }

    private function makeMasterTeacher(AcademicLevel $level): TeacherProfile
    {
        $user = User::factory()->create(['email' => 'mt-learn-'.uniqid().'@excellenteducators.test']);
        $user->assignRole(RoleName::MasterTeacher->value);
        $profile = TeacherProfile::query()->create([
            'user_id' => $user->id,
            'full_name' => $user->name,
            'status' => 'active',
        ]);
        $level->masterTeachers()->attach($profile->id);
        $profile->setRelation('user', $user);

        return $profile;
    }

    private function tokenFor(User $user): string
    {
        $this->app['auth']->forgetGuards();

        return $user->createToken('test')->plainTextToken;
    }
}
