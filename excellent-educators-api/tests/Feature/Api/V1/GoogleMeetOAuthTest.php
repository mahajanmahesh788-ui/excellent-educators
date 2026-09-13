<?php

namespace Tests\Feature\Api\V1;

use App\Enums\RoleName;
use App\Meetings\GoogleMeetService;
use App\Models\GoogleOAuthToken;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class GoogleMeetOAuthTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
        config([
            'google.meet.driver' => 'google',
            'google.meet.client_id' => 'test-client-id',
            'google.meet.client_secret' => 'test-client-secret',
            'google.meet.redirect_uri' => 'http://127.0.0.1:8001/auth/google/callback',
            'google.meet.scope' => 'https://www.googleapis.com/auth/meetings.space.created',
        ]);
    }

    public function test_callback_stores_encrypted_refresh_token(): void
    {
        Http::fake([
            'oauth2.googleapis.com/token' => Http::response([
                'access_token' => 'ya29.test-access',
                'expires_in' => 3600,
                'refresh_token' => '1//test-refresh-token',
                'token_type' => 'Bearer',
            ]),
            'www.googleapis.com/oauth2/v2/userinfo' => Http::response([
                'email' => 'meet-owner@example.com',
            ]),
        ]);

        $this->withSession(['google_oauth_state' => 'state-abc'])
            ->get('/auth/google/callback?code=auth-code&state=state-abc')
            ->assertOk()
            ->assertSee('Google Meet connected');

        $token = GoogleOAuthToken::query()->first();
        $this->assertNotNull($token);
        $this->assertSame('1//test-refresh-token', $token->refresh_token);
        $this->assertSame('meet-owner@example.com', $token->google_email);
        $this->assertStringNotContainsString('1//test-refresh-token', $token->getRawOriginal('refresh_token'));
    }

    public function test_admin_can_create_meet_space_after_oauth(): void
    {
        GoogleOAuthToken::query()->create([
            'purpose' => GoogleOAuthToken::PURPOSE_MEET,
            'refresh_token' => '1//stored-refresh',
            'scopes' => 'https://www.googleapis.com/auth/meetings.space.created',
            'connected_at' => now(),
        ]);

        Http::fake([
            'oauth2.googleapis.com/token' => Http::response([
                'access_token' => 'ya29.refreshed',
                'expires_in' => 3600,
            ]),
            'meet.googleapis.com/v2/spaces' => Http::response([
                'name' => 'spaces/abc-def-ghi',
                'meetingUri' => 'https://meet.google.com/abc-defg-hij',
                'meetingCode' => 'abc-defg-hij',
            ], 200),
        ]);

        $admin = User::factory()->create();
        $admin->assignRole(RoleName::OperationalAdmin->value);

        $this->withToken($admin->createToken('test')->plainTextToken)
            ->postJson('/api/v1/admin/google/meet/spaces')
            ->assertCreated()
            ->assertJsonPath('data.meeting_uri', 'https://meet.google.com/abc-defg-hij')
            ->assertJsonMissingPath('data.client_secret')
            ->assertJsonMissingPath('error');

        $created = app(GoogleMeetService::class)->createSpace();
        $this->assertSame('https://meet.google.com/abc-defg-hij', $created->meetUrl);
    }

    public function test_oauth_callback_rejects_bad_state(): void
    {
        $this->withSession(['google_oauth_state' => 'expected'])
            ->get('/auth/google/callback?code=auth-code&state=wrong')
            ->assertStatus(400)
            ->assertSee('Invalid Google callback');

        $this->assertSame(0, GoogleOAuthToken::query()->count());
    }

    public function test_admin_can_start_google_authorization(): void
    {
        $admin = User::factory()->create();
        $admin->assignRole(RoleName::OperationalAdmin->value);

        $payload = $this->withToken($admin->createToken('test')->plainTextToken)
            ->postJson('/api/v1/admin/google/meet/authorize')
            ->assertOk()
            ->json('data');

        $this->assertStringContainsString('accounts.google.com', $payload['authorization_url']);
        $this->assertStringContainsString('test-client-id', $payload['authorization_url']);
        $this->assertArrayNotHasKey('client_secret', $payload);

        parse_str(parse_url($payload['authorization_url'], PHP_URL_QUERY) ?: '', $query);
        $state = $query['state'] ?? '';
        $this->assertNotSame('', $state);

        Http::fake([
            'oauth2.googleapis.com/token' => Http::response([
                'access_token' => 'ya29.admin',
                'expires_in' => 3600,
                'refresh_token' => '1//admin-refresh',
            ]),
            'www.googleapis.com/oauth2/v2/userinfo' => Http::response(['email' => 'admin@example.com']),
        ]);

        $this->get('/auth/google/callback?code=from-admin&state='.$state)
            ->assertOk()
            ->assertSee('Google Meet connected');

        $this->assertSame('1//admin-refresh', GoogleOAuthToken::query()->first()?->refresh_token);
    }
}
