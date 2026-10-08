<?php

namespace Tests\Feature\Api\V1;

use App\Models\InterestOption;
use App\Models\InterestQuestion;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class OnboardingInterestParentTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
    }

    public function test_admin_can_upsert_interest_and_parent_questions(): void
    {
        $admin = $this->makeAdmin();

        $interest = $this->withToken($this->tokenFor($admin))
            ->putJson('/api/v1/admin/interest-questions', [
                'questions' => [[
                    'question_text' => 'What do you enjoy?',
                    'allow_other' => true,
                    'max_selections' => 5,
                    'options' => [
                        ['option_text' => 'Music'],
                        ['option_text' => 'Sports'],
                        ['option_text' => 'Coding'],
                    ],
                ]],
            ])
            ->assertOk()
            ->json('data');

        $this->assertCount(1, $interest);
        $this->assertSame('What do you enjoy?', $interest[0]['question_text']);
        $this->assertCount(3, $interest[0]['options']);

        $parent = $this->withToken($this->tokenFor($admin))
            ->putJson('/api/v1/admin/parent-questions', [
                'questions' => [
                    [
                        'question_text' => 'Guardian full name',
                        'question_type' => 'text',
                        'options' => [],
                    ],
                    [
                        'question_text' => 'Preferred contact time',
                        'question_type' => 'options',
                        'options' => [
                            ['option_text' => 'Morning'],
                            ['option_text' => 'Evening'],
                        ],
                    ],
                ],
            ])
            ->assertOk()
            ->json('data');

        $this->assertCount(2, $parent);
        $this->assertSame('text', $parent[0]['question_type']);
        $this->assertSame('options', $parent[1]['question_type']);
    }

    public function test_student_interest_other_persists_as_option_for_next_student(): void
    {
        $admin = $this->makeAdmin();
        $this->seedInterest($admin);
        $studentA = $this->makeStudentViaAdmin($admin, 'Student A', 'a');
        $studentB = $this->makeStudentViaAdmin($admin, 'Student B', 'b');

        $question = InterestQuestion::query()->firstOrFail();
        $music = $question->options()->where('option_text', 'Music')->firstOrFail();

        $me = $this->withToken($this->tokenFor($studentA->user))
            ->getJson('/api/v1/auth/me')
            ->assertOk()
            ->json('data');

        $this->assertTrue($me['must_complete_interest_profile']);
        $this->assertFalse($me['must_complete_parent_intake']);

        $this->withToken($this->tokenFor($studentA->user))
            ->postJson('/api/v1/student/interest-profile', [
                'answers' => [[
                    'question_id' => $question->id,
                    'option_ids' => [$music->id],
                    'other_text' => 'Chess',
                ]],
            ])
            ->assertOk()
            ->assertJsonPath('data.must_complete_interest_profile', false);

        $this->assertDatabaseHas('interest_options', [
            'interest_question_id' => $question->id,
            'normalized_key' => 'chess',
            'source' => 'student',
        ]);

        $profileB = $this->withToken($this->tokenFor($studentB->user))
            ->getJson('/api/v1/student/interest-profile')
            ->assertOk()
            ->json('data');

        $labels = collect($profileB['questions'][0]['options'])->pluck('option_text')->all();
        $this->assertContains('Chess', $labels);
    }

    public function test_student_can_skip_parent_intake(): void
    {
        $admin = $this->makeAdmin();
        $this->seedInterest($admin);
        $this->seedParent($admin);
        $student = $this->makeStudentViaAdmin($admin);

        $question = InterestQuestion::query()->firstOrFail();
        $music = $question->options()->where('option_text', 'Music')->firstOrFail();

        $this->withToken($this->tokenFor($student->user))
            ->postJson('/api/v1/student/interest-profile', [
                'answers' => [[
                    'question_id' => $question->id,
                    'option_ids' => [$music->id],
                ]],
            ])
            ->assertOk();

        $this->withToken($this->tokenFor($student->user))
            ->postJson('/api/v1/student/parent-intake/skip')
            ->assertOk()
            ->assertJsonPath('data.must_complete_parent_intake', false)
            ->assertJsonPath('data.parent_intake_skipped', true);
    }

    public function test_interest_enforces_max_five_selections(): void
    {
        $admin = $this->makeAdmin();
        $this->seedInterest($admin, maxSelections: 5, extraOptions: ['Art', 'Dance']);
        $student = $this->makeStudentViaAdmin($admin);

        $question = InterestQuestion::query()->firstOrFail();
        $ids = $question->options()->pluck('id')->take(5)->all();

        $this->withToken($this->tokenFor($student->user))
            ->postJson('/api/v1/student/interest-profile', [
                'answers' => [[
                    'question_id' => $question->id,
                    'option_ids' => $ids,
                    'other_text' => 'Drama',
                ]],
            ])
            ->assertStatus(422);
    }

    public function test_admin_save_preserves_student_sourced_options(): void
    {
        $admin = $this->makeAdmin();
        $payload = $this->seedInterest($admin);
        $questionId = $payload[0]['id'];

        InterestOption::query()->create([
            'interest_question_id' => $questionId,
            'option_text' => 'Chess',
            'normalized_key' => 'chess',
            'source' => 'student',
            'display_order' => 99,
            'is_active' => true,
            'usage_count' => 2,
        ]);

        $this->withToken($this->tokenFor($admin))
            ->putJson('/api/v1/admin/interest-questions', [
                'questions' => [[
                    'id' => $questionId,
                    'question_text' => 'What do you enjoy?',
                    'allow_other' => true,
                    'max_selections' => 5,
                    'options' => [
                        ['id' => $payload[0]['options'][0]['id'], 'option_text' => 'Music'],
                        ['id' => $payload[0]['options'][1]['id'], 'option_text' => 'Sports'],
                        ['id' => $payload[0]['options'][2]['id'], 'option_text' => 'Coding'],
                    ],
                ]],
            ])
            ->assertOk();

        $this->assertDatabaseHas('interest_options', [
            'interest_question_id' => $questionId,
            'normalized_key' => 'chess',
            'is_active' => true,
            'source' => 'student',
        ]);
    }

    public function test_student_profile_exposes_interest_and_parent_summaries(): void
    {
        $admin = $this->makeAdmin();
        $this->seedInterest($admin);
        $this->seedParent($admin);
        $student = $this->makeStudentViaAdmin($admin);

        $iQuestion = InterestQuestion::query()->firstOrFail();
        $music = $iQuestion->options()->where('option_text', 'Music')->firstOrFail();
        $pQuestion = \App\Models\ParentQuestion::query()->firstOrFail();

        $this->withToken($this->tokenFor($student->user))
            ->postJson('/api/v1/student/interest-profile', [
                'answers' => [[
                    'question_id' => $iQuestion->id,
                    'option_ids' => [$music->id],
                    'other_text' => 'Chess',
                ]],
            ])
            ->assertOk();

        $this->withToken($this->tokenFor($student->user))
            ->postJson('/api/v1/student/parent-intake/skip')
            ->assertOk();

        $profile = $this->withToken($this->tokenFor($student->user))
            ->getJson('/api/v1/student/profile')
            ->assertOk()
            ->json('data');

        $this->assertTrue($profile['interest_profile']['completed']);
        $this->assertSame('What do you enjoy?', $profile['interest_profile']['answers'][0]['question']);
        $this->assertContains('Music', $profile['interest_profile']['answers'][0]['values']);
        $this->assertContains('Other: Chess', $profile['interest_profile']['answers'][0]['values']);
        $this->assertTrue($profile['parent_intake']['available']);
        $this->assertFalse($profile['parent_intake']['completed']);
        $this->assertTrue($profile['parent_intake']['skipped']);
        $this->assertSame([], $profile['parent_intake']['answers']);

        $this->withToken($this->tokenFor($student->user))
            ->postJson('/api/v1/student/parent-intake', [
                'answers' => [[
                    'question_id' => $pQuestion->id,
                    'text_answer' => 'Priya Sharma',
                ]],
            ])
            ->assertOk();

        $adminShow = $this->withToken($this->tokenFor($admin))
            ->getJson('/api/v1/admin/students/'.$student->id)
            ->assertOk()
            ->json('data');

        $this->assertTrue($adminShow['parent_intake']['completed']);
        $this->assertFalse($adminShow['parent_intake']['skipped']);
        $this->assertSame('Priya Sharma', $adminShow['parent_intake']['answers'][0]['values'][0]);

        $list = $this->withToken($this->tokenFor($admin))
            ->getJson('/api/v1/admin/students')
            ->assertOk()
            ->json('data');

        $this->assertArrayNotHasKey('interest_profile', $list[0] ?? []);
        $this->assertArrayNotHasKey('parent_intake', $list[0] ?? []);
    }

    public function test_student_can_revisit_view_saved_answers_and_resubmit(): void
    {
        $admin = $this->makeAdmin();
        $this->seedInterest($admin);
        $this->seedParent($admin);
        $student = $this->makeStudentViaAdmin($admin);

        $iQuestion = InterestQuestion::query()->firstOrFail();
        $music = $iQuestion->options()->where('option_text', 'Music')->firstOrFail();
        $sports = $iQuestion->options()->where('option_text', 'Sports')->firstOrFail();

        // 1. Submit initial interest
        $this->withToken($this->tokenFor($student->user))
            ->postJson('/api/v1/student/interest-profile', [
                'answers' => [[
                    'question_id' => $iQuestion->id,
                    'option_ids' => [$music->id],
                ]],
            ])
            ->assertOk();

        // 2. Fetch interest profile again - saved_answers should contain music
        $profile = $this->withToken($this->tokenFor($student->user))
            ->getJson('/api/v1/student/interest-profile')
            ->assertOk()
            ->json('data');

        $this->assertTrue($profile['completed']);
        $this->assertArrayHasKey($iQuestion->id, $profile['saved_answers']);
        $this->assertEquals([$music->id], $profile['saved_answers'][$iQuestion->id]['option_ids']);

        // 3. Resubmit/update interests with sports instead
        $this->withToken($this->tokenFor($student->user))
            ->postJson('/api/v1/student/interest-profile', [
                'answers' => [[
                    'question_id' => $iQuestion->id,
                    'option_ids' => [$sports->id],
                ]],
            ])
            ->assertOk();

        // Verify update persisted
        $updatedProfile = $this->withToken($this->tokenFor($student->user))
            ->getJson('/api/v1/student/interest-profile')
            ->assertOk()
            ->json('data');
        $this->assertEquals([$sports->id], $updatedProfile['saved_answers'][$iQuestion->id]['option_ids']);

        // 4. Submit parent intake then update it
        $pQuestion = \App\Models\ParentQuestion::query()->firstOrFail();
        $this->withToken($this->tokenFor($student->user))
            ->postJson('/api/v1/student/parent-intake', [
                'answers' => [[
                    'question_id' => $pQuestion->id,
                    'text_answer' => 'Parent Initial',
                ]],
            ])
            ->assertOk();

        $this->withToken($this->tokenFor($student->user))
            ->postJson('/api/v1/student/parent-intake', [
                'answers' => [[
                    'question_id' => $pQuestion->id,
                    'text_answer' => 'Parent Updated',
                ]],
            ])
            ->assertOk();

        $pData = $this->withToken($this->tokenFor($student->user))
            ->getJson('/api/v1/student/parent-intake')
            ->assertOk()
            ->json('data');
        $this->assertTrue($pData['completed']);
        $this->assertEquals('Parent Updated', $pData['saved_answers'][$pQuestion->id]['text_answer']);
    }

    /**
     * @param  list<string>  $extraOptions
     * @return list<array<string, mixed>>
     */
    private function seedInterest($admin, int $maxSelections = 5, array $extraOptions = []): array
    {
        $options = [
            ['option_text' => 'Music'],
            ['option_text' => 'Sports'],
            ['option_text' => 'Coding'],
        ];
        foreach ($extraOptions as $label) {
            $options[] = ['option_text' => $label];
        }

        return $this->withToken($this->tokenFor($admin))
            ->putJson('/api/v1/admin/interest-questions', [
                'questions' => [[
                    'question_text' => 'What do you enjoy?',
                    'allow_other' => true,
                    'max_selections' => $maxSelections,
                    'options' => $options,
                ]],
            ])
            ->assertOk()
            ->json('data');
    }

    private function seedParent($admin): void
    {
        $this->withToken($this->tokenFor($admin))
            ->putJson('/api/v1/admin/parent-questions', [
                'questions' => [[
                    'question_text' => 'Guardian full name',
                    'question_type' => 'text',
                    'options' => [],
                ]],
            ])
            ->assertOk();
    }
}
