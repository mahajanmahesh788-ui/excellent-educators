<?php

namespace Tests\Feature\Api\V1;

use App\Enums\RoleName;
use App\Enums\UserStatus;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RoleSeeder::class);
    }

    public function test_login_returns_token_and_user_envelope(): void
    {
        $user = User::factory()->create([
            'email' => 'admin1@excellenteducators.test',
            'password' => 'ChangeMeAdmin1!',
            'status' => UserStatus::Active,
        ]);
        $user->assignRole(RoleName::SuperAdmin->value);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'admin1@excellenteducators.test',
            'password' => 'ChangeMeAdmin1!',
        ]);

        $response
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.user.email', 'admin1@excellenteducators.test')
            ->assertJsonPath('data.token_type', 'Bearer')
            ->assertJsonStructure([
                'success',
                'message',
                'data' => ['token', 'token_type', 'expires_in', 'user' => ['id', 'name', 'email', 'roles']],
                'meta' => ['request_id'],
            ]);
    }

    public function test_login_rejects_invalid_credentials(): void
    {
        User::factory()->create([
            'email' => 'admin1@excellenteducators.test',
            'password' => 'ChangeMeAdmin1!',
        ]);

        $this->postJson('/api/v1/auth/login', [
            'email' => 'admin1@excellenteducators.test',
            'password' => 'wrong-password',
        ])
            ->assertUnauthorized()
            ->assertJsonPath('success', false)
            ->assertJsonPath('error.code', 'INVALID_CREDENTIALS');
    }

    public function test_me_requires_authentication(): void
    {
        $this->getJson('/api/v1/auth/me')
            ->assertUnauthorized()
            ->assertJsonPath('error.code', 'UNAUTHENTICATED');
    }

    public function test_me_and_logout_with_token(): void
    {
        $user = User::factory()->create([
            'email' => 'admin2@excellenteducators.test',
            'password' => 'ChangeMeAdmin2!',
        ]);
        $user->assignRole(RoleName::OperationalAdmin->value);

        $login = $this->postJson('/api/v1/auth/login', [
            'email' => 'admin2@excellenteducators.test',
            'password' => 'ChangeMeAdmin2!',
        ])->assertOk();

        $token = $login->json('data.token');

        $this->withToken($token)
            ->getJson('/api/v1/auth/me')
            ->assertOk()
            ->assertJsonPath('data.email', 'admin2@excellenteducators.test')
            ->assertJsonPath('data.roles.0', RoleName::OperationalAdmin->value);

        $this->withToken($token)
            ->postJson('/api/v1/auth/logout')
            ->assertOk();

        $this->app['auth']->forgetGuards();

        $this->withToken($token)
            ->getJson('/api/v1/auth/me')
            ->assertUnauthorized();
    }

    public function test_authenticated_user_can_change_password(): void
    {
        $user = User::factory()->create([
            'email' => 'password-change@excellenteducators.test',
            'password' => 'ChangeMeAdmin1!',
        ]);
        $user->assignRole(RoleName::OperationalAdmin->value);

        $token = $this->postJson('/api/v1/auth/login', [
            'email' => 'password-change@excellenteducators.test',
            'password' => 'ChangeMeAdmin1!',
        ])->assertOk()->json('data.token');

        $this->withToken($token)->putJson('/api/v1/auth/password', [
            'current_password' => 'ChangeMeAdmin1!',
            'password' => 'NewSecurePass1!',
            'password_confirmation' => 'NewSecurePass1!',
        ])->assertOk()
            ->assertJsonPath('success', true);

        $this->app['auth']->forgetGuards();

        $this->withToken($token)
            ->getJson('/api/v1/auth/me')
            ->assertUnauthorized();

        $this->postJson('/api/v1/auth/login', [
            'email' => 'password-change@excellenteducators.test',
            'password' => 'NewSecurePass1!',
        ])->assertOk();
    }

    public function test_change_password_rejects_incorrect_current_password(): void
    {
        $user = User::factory()->create([
            'email' => 'password-wrong@excellenteducators.test',
            'password' => 'ChangeMeAdmin1!',
        ]);
        $user->assignRole(RoleName::OperationalAdmin->value);

        $token = $this->postJson('/api/v1/auth/login', [
            'email' => 'password-wrong@excellenteducators.test',
            'password' => 'ChangeMeAdmin1!',
        ])->assertOk()->json('data.token');

        $this->withToken($token)->putJson('/api/v1/auth/password', [
            'current_password' => 'WrongPass1!',
            'password' => 'NewSecurePass1!',
            'password_confirmation' => 'NewSecurePass1!',
        ])->assertUnprocessable()
            ->assertJsonPath('error.code', 'VALIDATION_ERROR')
            ->assertJsonStructure(['error' => ['details' => ['current_password']]]);
    }

    public function test_change_password_requires_authentication(): void
    {
        $this->putJson('/api/v1/auth/password', [
            'current_password' => 'ChangeMeAdmin1!',
            'password' => 'NewSecurePass1!',
            'password_confirmation' => 'NewSecurePass1!',
        ])->assertUnauthorized();
    }
}
