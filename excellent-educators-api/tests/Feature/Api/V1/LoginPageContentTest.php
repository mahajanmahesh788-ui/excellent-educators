<?php

namespace Tests\Feature\Api\V1;

use App\Enums\RoleName;
use App\Models\User;
use Database\Seeders\LoginPageContentSeeder;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class LoginPageContentTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed([RoleSeeder::class, LoginPageContentSeeder::class]);
    }

    public function test_public_can_fetch_login_page_content(): void
    {
        $this->getJson('/api/v1/auth/login-page')
            ->assertOk()
            ->assertJsonPath('data.tagline', 'Building Careers. Creating Leaders.')
            ->assertJsonPath('data.form_title', 'Welcome back')
            ->assertJsonCount(3, 'data.pillars');
    }

    public function test_admin_can_view_and_update_login_page_content(): void
    {
        $admin = $this->makeAdmin();
        $token = $this->tokenFor($admin);

        $this->withToken($token)->getJson('/api/v1/admin/login-page')
            ->assertOk()
            ->assertJsonPath('data.forgot_form_title', 'Reset your password');

        $this->withToken($token)->putJson('/api/v1/admin/login-page', [
            'headline' => 'Guidance with purpose',
            'form_title' => 'Sign in',
            'pillars' => [
                [
                    'icon' => 'school_outlined',
                    'title' => 'Learn deeply',
                    'body' => 'Build skills that last beyond exams.',
                ],
            ],
            'trust_signals' => [
                [
                    'icon' => 'verified_outlined',
                    'value' => 'Trusted',
                    'label' => 'by families',
                ],
            ],
            'testimonials_heading' => 'What families say',
            'testimonials' => [
                [
                    'quote' => 'A clear path for my child.',
                    'attribution' => 'Anita',
                    'role' => 'Parent',
                ],
            ],
        ])
            ->assertOk()
            ->assertJsonPath('data.headline', 'Guidance with purpose')
            ->assertJsonPath('data.form_title', 'Sign in')
            ->assertJsonCount(1, 'data.pillars')
            ->assertJsonCount(1, 'data.trust_signals')
            ->assertJsonPath('data.testimonials_heading', 'What families say')
            ->assertJsonCount(1, 'data.testimonials');

        $this->getJson('/api/v1/auth/login-page')
            ->assertOk()
            ->assertJsonPath('data.headline', 'Guidance with purpose')
            ->assertJsonPath('data.trust_signals.0.value', 'Trusted');
    }

    public function test_public_login_page_includes_trust_and_testimonials(): void
    {
        $this->getJson('/api/v1/auth/login-page')
            ->assertOk()
            ->assertJsonCount(3, 'data.trust_signals')
            ->assertJsonCount(3, 'data.stories')
            ->assertJsonCount(4, 'data.testimonials')
            ->assertJsonPath('data.why_heading', 'A clearer way to grow')
            ->assertJsonPath('data.trust_signals.0.value', 'Mentor first')
            ->assertJsonPath('data.testimonials_heading', 'Voices from our community');
    }

    public function test_non_admin_cannot_update_login_page_content(): void
    {
        $student = $this->makeStudent('login-content@excellenteducators.test');

        $this->withToken($this->tokenFor($student))->putJson('/api/v1/admin/login-page', [
            'headline' => 'Hacked',
        ])->assertForbidden();
    }

    private function makeStudent(string $email): User
    {
        $user = User::factory()->create([
            'email' => $email,
            'name' => 'Login Student',
        ]);
        $user->assignRole(RoleName::Student->value);

        return $user;
    }
}
