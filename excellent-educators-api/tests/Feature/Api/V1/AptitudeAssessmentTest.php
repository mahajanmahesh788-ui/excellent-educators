<?php

namespace Tests\Feature\Api\V1;

use App\Enums\BatchStatus;
use App\Models\AcademicLevel;
use App\Models\AptitudeAssessment;
use App\Models\Batch;
use App\Models\StudentLevelJourney;
use App\Models\StudentProfile;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Testing\TestResponse;
use Tests\TestCase;

class AptitudeAssessmentTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed([RoleSeeder::class]);
    }

    public function test_admin_can_create_assessment(): void
    {
        $admin = $this->makeAdmin();

        $response = $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/assessments', [
            'title' => 'Aptitude Assessment 1',
            'description' => 'Find your strengths',
            'questions' => [$this->questionPayload()],
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.title', 'Aptitude Assessment 1')
            ->assertJsonPath('data.questions.0.options.0.dimension_codes', ['CR'])
            ->assertJsonPath('data.status', 'draft');

        $this->assertDatabaseHas('aptitude_assessments', [
            'title' => 'Aptitude Assessment 1',
        ]);
        $this->assertDatabaseHas('audit_logs', ['action' => 'assessment.created']);
    }

    public function test_invalid_dimension_code_is_rejected(): void
    {
        $admin = $this->makeAdmin();

        $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/assessments', [
            'title' => 'Bad codes',
            'questions' => [[
                'question_text' => 'Which activity do you enjoy most?',
                'options' => [
                    ['option_text' => 'Solving problems', 'dimension_codes' => ['p1']],
                ],
            ]],
        ])->assertStatus(422)
            ->assertJsonPath('error.code', 'VALIDATION_ERROR');
    }

    public function test_valid_dimension_codes_are_accepted(): void
    {
        $admin = $this->makeAdmin();

        $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/assessments', [
            'title' => 'All dimensions',
            'questions' => [[
                'question_text' => 'Pick one',
                'options' => [
                    ['option_text' => 'P', 'dimension_codes' => ['P']],
                    ['option_text' => 'I', 'dimension_codes' => ['I']],
                    ['option_text' => 'CF', 'dimension_codes' => ['CF']],
                    ['option_text' => 'L', 'dimension_codes' => ['L']],
                    ['option_text' => 'CM', 'dimension_codes' => ['CM']],
                    ['option_text' => 'DM', 'dimension_codes' => ['DM']],
                    ['option_text' => 'CR', 'dimension_codes' => ['CR']],
                    ['option_text' => 'CU', 'dimension_codes' => ['CU']],
                    ['option_text' => 'TW', 'dimension_codes' => ['TW']],
                    ['option_text' => 'FA', 'dimension_codes' => ['FA']],
                ],
            ]],
        ])->assertCreated();
    }

    public function test_assessment_cannot_be_activated_when_incomplete(): void
    {
        $admin = $this->makeAdmin();
        $token = $this->tokenFor($admin);

        $id = $this->withToken($token)->postJson('/api/v1/admin/assessments', [
            'title' => 'Empty',
        ])->assertCreated()->json('data.id');

        $this->withToken($token)->postJson("/api/v1/admin/assessments/{$id}/activate")
            ->assertStatus(422)
            ->assertJsonPath('error.code', 'ASSESSMENT_NOT_READY');
    }

    public function test_student_gets_applicable_active_assessment_without_dimension_codes(): void
    {
        $admin = $this->makeAdmin();
        $assessmentId = $this->createActiveAssessment($admin);
        $student = $this->makeStudent('cc1-student@excellenteducators.test');

        $payload = $this->withToken($this->tokenFor($student))->getJson('/api/v1/student/assessment')
            ->assertOk()
            ->assertJsonPath('data.available', true)
            ->assertJsonPath('data.assessment.id', $assessmentId)
            ->json('data');

        $this->assertArrayHasKey('options', $payload['assessment']['questions'][0]);
        $this->assertArrayNotHasKey('dimension_codes', $payload['assessment']['questions'][0]['options'][0]);
        $encoded = json_encode($payload);
        $this->assertStringNotContainsString('dimension_codes', $encoded);
        $this->assertStringNotContainsString('"CR"', $encoded);
    }

    public function test_student_cannot_get_assessment_after_completion(): void
    {
        $admin = $this->makeAdmin();
        $assessmentId = $this->createActiveAssessment($admin);
        $student = $this->makeStudent('done@excellenteducators.test');
        $this->submitAs($student, $assessmentId);

        $this->withToken($this->tokenFor($student))->getJson('/api/v1/student/assessment')
            ->assertOk()
            ->assertJsonPath('data.available', false)
            ->assertJsonPath('data.reason', 'already_completed');
    }

    public function test_student_cannot_submit_incomplete_assessment(): void
    {
        $admin = $this->makeAdmin();
        $assessmentId = $this->createActiveAssessment($admin, twoQuestions: true);
        $student = $this->makeStudent('incomplete@excellenteducators.test');
        $assessment = AptitudeAssessment::query()->with('questions.options')->findOrFail($assessmentId);
        $first = $assessment->questions->first();

        $this->withToken($this->tokenFor($student))->postJson("/api/v1/student/assessment/{$assessmentId}/submit", [
            'answers' => [[
                'question_id' => $first->id,
                'option_id' => $first->options->first()->id,
            ]],
        ])->assertStatus(422)
            ->assertJsonPath('error.code', 'ASSESSMENT_INCOMPLETE');
    }

    public function test_student_cannot_submit_twice(): void
    {
        $admin = $this->makeAdmin();
        $assessmentId = $this->createActiveAssessment($admin);
        $student = $this->makeStudent('twice@excellenteducators.test');
        $this->submitAs($student, $assessmentId)->assertCreated();

        $this->submitAs($student, $assessmentId)
            ->assertStatus(409)
            ->assertJsonPath('error.code', 'ASSESSMENT_ALREADY_SUBMITTED');
    }

    public function test_option_from_another_question_is_rejected(): void
    {
        $admin = $this->makeAdmin();
        $assessmentId = $this->createActiveAssessment($admin, twoQuestions: true);
        $student = $this->makeStudent('mismatch@excellenteducators.test');
        $assessment = AptitudeAssessment::query()->with('questions.options')->findOrFail($assessmentId);
        $first = $assessment->questions[0];
        $second = $assessment->questions[1];

        $this->withToken($this->tokenFor($student))->postJson("/api/v1/student/assessment/{$assessmentId}/submit", [
            'answers' => [
                [
                    'question_id' => $first->id,
                    'option_id' => $second->options->first()->id,
                ],
                [
                    'question_id' => $second->id,
                    'option_id' => $second->options->first()->id,
                ],
            ],
        ])->assertStatus(422);
    }

    public function test_result_calculates_all_ten_dimensions_including_zeros(): void
    {
        $admin = $this->makeAdmin();
        $assessmentId = $this->createActiveAssessment($admin);
        $student = $this->makeStudent('result@excellenteducators.test');
        $payload = $this->submitAs($student, $assessmentId)->assertCreated()->json('data');

        $this->assertArrayHasKey('id', $payload);
        $this->assertArrayNotHasKey('dimensions', $payload);

        $this->assertDatabaseCount('aptitude_assessment_result_dimensions', 10);

        $this->withToken($this->tokenFor($student))->getJson('/api/v1/student/results')
            ->assertForbidden()
            ->assertJsonPath('error.code', 'FORBIDDEN');
    }

    public function test_admin_sees_submission_indicators_after_student_submits(): void
    {
        $admin = $this->makeAdmin();
        $assessmentId = $this->createActiveAssessment($admin);
        $student = $this->makeStudent('admin-view@excellenteducators.test');
        $this->submitAs($student, $assessmentId)->assertCreated();

        $this->withToken($this->tokenFor($admin))->getJson('/api/v1/admin/assessments')
            ->assertOk()
            ->assertJsonPath('data.0.submitted_attempts_count', 1);

        $this->withToken($this->tokenFor($admin))->getJson("/api/v1/admin/assessments/{$assessmentId}")
            ->assertOk()
            ->assertJsonPath('data.submitted_attempts_count', 1);

        $this->withToken($this->tokenFor($admin))->getJson("/api/v1/admin/assessments/{$assessmentId}/attempts")
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.dimensions.0.code', 'P');

        $studentProfile = StudentProfile::query()->whereHas('user', fn ($q) => $q->where('email', 'admin-view@excellenteducators.test'))->firstOrFail();

        $this->withToken($this->tokenFor($admin))->getJson("/api/v1/admin/students/{$studentProfile->id}")
            ->assertOk()
            ->assertJsonPath('data.aptitude_assessment.status', 'submitted')
            ->assertJsonPath('data.aptitude_assessment.assessment_title', 'Aptitude Test');

        $this->withToken($this->tokenFor($admin))->getJson("/api/v1/admin/students/{$studentProfile->id}/results")
            ->assertOk()
            ->assertJsonCount(1, 'data');
    }

    public function test_promote_to_level_two_requires_level_two_assessment_and_restarts_journey(): void
    {
        $admin = $this->makeAdmin();
        $token = $this->tokenFor($admin);

        $level1 = AcademicLevel::query()->where('name', 'Level 1')->firstOrFail();
        $level1Assessment = $this->createActiveAssessment($admin, title: 'Level 1 ACD');

        $studentUser = $this->makeStudent('promote-l2-assess@excellenteducators.test');
        $student = StudentProfile::query()->where('user_id', $studentUser->id)->firstOrFail();
        $this->submitAs($studentUser, $level1Assessment)->assertCreated();

        $this->withToken($this->tokenFor($studentUser))->getJson('/api/v1/student/assessment')
            ->assertOk()
            ->assertJsonPath('data.available', false)
            ->assertJsonPath('data.reason', 'already_completed');

        $level2 = AcademicLevel::query()->create([
            'name' => 'Level 2',
            'number' => 2,
            'academic_year' => 2026,
            'status' => 'active',
        ]);
        Batch::query()->create([
            'level_id' => $level2->id,
            'name' => 'Batch 1',
            'academic_year' => 2026,
            'year' => 2026,
            'month' => 10,
            'enrolled_watermark' => 0,
            'status' => BatchStatus::Active,
            'starts_on' => now()->toDateString(),
        ]);

        $level2Assessment = $this->createActiveAssessment(
            $admin,
            title: 'Level 2 DDDC',
            assignToLevel: $level2,
        );

        $this->withToken($token)->postJson("/api/v1/admin/students/{$student->id}/promote", [
            'level_id' => $level2->id,
        ])->assertOk();

        $student->refresh();
        $this->assertSame($level2->id, $student->level_id);

        $openJourney = StudentLevelJourney::query()
            ->where('student_id', $student->id)
            ->whereNull('ended_at')
            ->first();
        $this->assertNotNull($openJourney);
        $this->assertSame($level2->id, $openJourney->level_id);

        $this->withToken($this->tokenFor($studentUser))->getJson('/api/v1/student/assessment')
            ->assertOk()
            ->assertJsonPath('data.available', true)
            ->assertJsonPath('data.assessment.id', $level2Assessment)
            ->assertJsonPath('data.assessment.title', 'Level 2 DDDC');

        // Level 1 assessment must not be offered again.
        $this->assertNotSame($level1Assessment, $level2Assessment);
        $this->assertTrue($level1->aptitudeAssessments()->whereKey($level1Assessment)->exists());
    }

    private function createActiveAssessment(
        User $admin,
        bool $twoQuestions = false,
        string $title = 'Aptitude Test',
        ?AcademicLevel $assignToLevel = null,
    ): string {
        $questions = [$this->questionPayload()];
        if ($twoQuestions) {
            $questions[] = [
                'question_text' => 'How do you prefer to work?',
                'options' => [
                    ['option_text' => 'With others', 'dimension_codes' => ['TW']],
                    ['option_text' => 'Leading', 'dimension_codes' => ['L']],
                ],
            ];
        }

        $token = $this->tokenFor($admin);
        $id = $this->withToken($token)->postJson('/api/v1/admin/assessments', [
            'title' => $title,
            'questions' => $questions,
        ])->assertCreated()->json('data.id');

        $this->withToken($token)->postJson("/api/v1/admin/assessments/{$id}/activate")
            ->assertOk()
            ->assertJsonPath('data.status', 'active');

        $level = $assignToLevel ?? AcademicLevel::query()->where('name', 'Level 1')->firstOrFail();
        $this->withToken($token)->putJson("/api/v1/admin/levels/{$level->id}/assessments", [
            'assessment_ids' => [$id],
        ])->assertOk();

        return $id;
    }

    /**
     * @return array<string, mixed>
     */
    private function questionPayload(): array
    {
        return [
            'question_text' => 'Which activity do you enjoy most?',
            'options' => [
                ['option_text' => 'Solving problems', 'dimension_codes' => ['CR']],
                ['option_text' => 'Working with others', 'dimension_codes' => ['TW']],
                ['option_text' => 'Taking responsibility', 'dimension_codes' => ['L']],
                ['option_text' => 'Communicating with people', 'dimension_codes' => ['CM']],
            ],
        ];
    }

    private function submitAs(User $student, string $assessmentId): TestResponse
    {
        $assessment = AptitudeAssessment::query()->with('questions.options')->findOrFail($assessmentId);
        $answers = $assessment->questions->map(fn ($question) => [
            'question_id' => $question->id,
            'option_id' => $question->options->first()->id,
        ])->all();

        return $this->withToken($this->tokenFor($student))->postJson(
            "/api/v1/student/assessment/{$assessmentId}/submit",
            ['answers' => $answers],
        );
    }

    private function makeStudent(string $email): User
    {
        $admin = User::query()->where('email', 'ops-aptitude@excellenteducators.test')->first() ?? $this->makeAdmin();

        $id = $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/students', [
            'name' => 'Student '.$email,
            'email' => $email,
            'password' => 'StudentPass1!',
            'phone' => '9000000000',
            'class_grade' => 5,
            'gender' => 'male',
        ])->assertCreated()->json('data.id');

        return StudentProfile::query()->findOrFail($id)->user;
    }
}
