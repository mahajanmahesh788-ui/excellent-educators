<?php

namespace Tests\Feature\Api\V1;

use App\Support\PolicyTerms;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AcceptTermsTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
    }

    public function test_student_must_accept_terms_until_current_version_recorded(): void
    {
        $admin = $this->makeAdmin();
        $student = $this->makeStudentViaAdmin($admin);
        $token = $this->tokenFor($student->user);

        $this->withToken($token)
            ->getJson('/api/v1/auth/me')
            ->assertOk()
            ->assertJsonPath('data.must_accept_terms', true)
            ->assertJsonPath('data.terms_accepted_version', null)
            ->assertJsonPath('data.terms_current_version', PolicyTerms::CURRENT_VERSION);

        $this->withToken($token)
            ->postJson('/api/v1/student/accept-terms')
            ->assertOk()
            ->assertJsonPath('data.must_accept_terms', false)
            ->assertJsonPath('data.terms_accepted_version', PolicyTerms::CURRENT_VERSION)
            ->assertJsonPath('data.terms_current_version', PolicyTerms::CURRENT_VERSION);

        $student->user->refresh();
        $this->assertNotNull($student->user->terms_accepted_at);
        $this->assertSame(PolicyTerms::CURRENT_VERSION, $student->user->terms_accepted_version);

        $this->withToken($token)
            ->getJson('/api/v1/auth/me')
            ->assertOk()
            ->assertJsonPath('data.must_accept_terms', false);
    }

    public function test_student_must_reaccept_when_terms_version_changes(): void
    {
        $admin = $this->makeAdmin();
        $student = $this->makeStudentViaAdmin($admin);
        $user = $student->user;
        $user->forceFill([
            'terms_accepted_at' => now()->subDay(),
            'terms_accepted_version' => '2020-01-01',
        ])->save();

        $token = $this->tokenFor($user->fresh());

        $this->withToken($token)
            ->getJson('/api/v1/auth/me')
            ->assertOk()
            ->assertJsonPath('data.must_accept_terms', true)
            ->assertJsonPath('data.terms_accepted_version', '2020-01-01');

        $this->withToken($token)
            ->postJson('/api/v1/student/accept-terms')
            ->assertOk()
            ->assertJsonPath('data.must_accept_terms', false)
            ->assertJsonPath('data.terms_accepted_version', PolicyTerms::CURRENT_VERSION);
    }

    public function test_admin_cannot_use_student_accept_terms_endpoint(): void
    {
        $admin = $this->makeAdmin();

        $this->withToken($this->tokenFor($admin))
            ->postJson('/api/v1/student/accept-terms')
            ->assertForbidden();
    }
}
