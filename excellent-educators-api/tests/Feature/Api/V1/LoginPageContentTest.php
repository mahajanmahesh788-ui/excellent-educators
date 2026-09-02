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
            ->assertJsonCount(4, 'data.pillars');
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
        ])
            ->assertOk()
            ->assertJsonPath('data.headline', 'Guidance with purpose')
            ->assertJsonPath('data.form_title', 'Sign in')
            ->assertJsonCount(1, 'data.pillars');

        $this->getJson('/api/v1/auth/login-page')
            ->assertOk()
            ->assertJsonPath('data.headline', 'Guidance with purpose');
    }

    public function test_non_admin_cannot_update_login_page_content(): void
    {
        $student = $this->makeStudent('login-content@excellenteducators.test');

        $this->withToken($this->tokenFor($student))->putJson('/api/v1/admin/login-page', [
            'headline' => 'Hacked',
        ])->assertForbidden();
    }

    private function makeAdmin(): User
    {
        $user = User::factory()->create([
            'email' => 'login-admin@excellenteducators.test',
            'name' => 'Login Admin',
        ]);
        $user->assignRole(RoleName::OperationalAdmin->value);

        return $user;
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

    private function tokenFor(User $user): string
    {
        return $user->createToken('test')->plainTextToken;
    }
}
