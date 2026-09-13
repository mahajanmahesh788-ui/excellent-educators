<?php

namespace App\Meetings;

use App\Exceptions\ApiException;
use App\Models\GoogleOAuthToken;
use App\Models\TeacherProfile;
use App\Support\ErrorCode;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Throwable;

class GoogleMeetService implements GoogleMeetGateway
{
    public function isConnected(): bool
    {
        return filled($this->storedRefreshToken());
    }

    public function authorizationUrl(string $state): string
    {
        $this->assertClientConfigured();

        return 'https://accounts.google.com/o/oauth2/v2/auth?'.http_build_query([
            'client_id' => config('google.meet.client_id'),
            'redirect_uri' => $this->redirectUri(),
            'response_type' => 'code',
            'scope' => $this->scope(),
            'access_type' => 'offline',
            'prompt' => 'consent',
            'include_granted_scopes' => 'true',
            'state' => $state,
        ]);
    }

    public function startAuthorization(): array
    {
        $state = self::newState();
        $this->rememberState($state);

        return [
            'authorization_url' => $this->authorizationUrl($state),
            'redirect_uri' => $this->redirectUri(),
        ];
    }

    public function rememberState(string $state): void
    {
        Cache::put($this->stateCacheKey($state), true, now()->addMinutes(15));
    }

    public function consumeState(string $state): bool
    {
        if ($state === '') {
            return false;
        }

        $key = $this->stateCacheKey($state);
        if (! Cache::pull($key)) {
            return false;
        }

        return true;
    }

    private function stateCacheKey(string $state): string
    {
        return 'google.oauth.state.'.$state;
    }

    public function completeAuthorization(string $code): GoogleOAuthToken
    {
        $this->assertClientConfigured();

        $response = Http::asForm()->acceptJson()->post('https://oauth2.googleapis.com/token', [
            'code' => $code,
            'client_id' => config('google.meet.client_id'),
            'client_secret' => config('google.meet.client_secret'),
            'redirect_uri' => $this->redirectUri(),
            'grant_type' => 'authorization_code',
        ]);

        if (! $response->successful()) {
            Log::error('Google OAuth code exchange failed.', [
                'status' => $response->status(),
                'body' => $response->json(),
            ]);
            throw new ApiException(
                ErrorCode::GOOGLE_NOT_CONNECTED,
                'Google authorization failed. Please try connecting again.',
                502,
            );
        }

        $refresh = $response->json('refresh_token');
        $access = $response->json('access_token');
        if (! is_string($refresh) || $refresh === '') {
            Log::error('Google OAuth response did not include a refresh token.');
            throw new ApiException(
                ErrorCode::GOOGLE_NOT_CONNECTED,
                'Google did not return a refresh token. Revoke app access in Google Account and authorize again.',
                502,
            );
        }

        if (is_string($access) && $access !== '') {
            $this->cacheAccessToken($access, (int) ($response->json('expires_in') ?? 3500));
        }

        return GoogleOAuthToken::query()->updateOrCreate(
            ['purpose' => GoogleOAuthToken::PURPOSE_MEET],
            [
                'refresh_token' => $refresh,
                'scopes' => $this->scope(),
                'google_email' => $this->emailFromAccessToken(is_string($access) ? $access : null),
                'connected_at' => now(),
            ],
        );
    }

    public function createDailyMeet(TeacherProfile $teacher, string $date): CreatedGoogleMeet
    {
        return $this->createSpace();
    }

    public function createSpace(): CreatedGoogleMeet
    {
        try {
            $response = Http::withToken($this->accessToken())
                ->acceptJson()
                ->withBody('{}', 'application/json')
                ->post('https://meet.googleapis.com/v2/spaces');

            if (! $response->successful()) {
                Log::error('Google Meet space create failed.', [
                    'status' => $response->status(),
                    'body' => $response->json(),
                ]);
                throw $this->createFailed();
            }

            $json = $response->json() ?? [];
            $meetUrl = $json['meetingUri'] ?? null;
            $spaceName = $json['name'] ?? null;

            if (! is_string($meetUrl) || $meetUrl === '') {
                Log::error('Google Meet space response missing meetingUri.', ['body' => $json]);
                throw $this->createFailed();
            }

            return new CreatedGoogleMeet(
                meetUrl: $meetUrl,
                googleMeetingSpaceId: is_string($spaceName) ? $spaceName : null,
            );
        } catch (ApiException $exception) {
            throw $exception;
        } catch (Throwable $exception) {
            Log::error('Google Meet space creation threw.', ['message' => $exception->getMessage()]);
            throw $this->createFailed();
        }
    }

    public function connectionStatus(): array
    {
        $token = GoogleOAuthToken::query()->where('purpose', GoogleOAuthToken::PURPOSE_MEET)->first();

        return [
            'connected' => $token !== null && filled($token->refresh_token),
            'google_email' => $token?->google_email,
            'connected_at' => $token?->connected_at?->toIso8601String(),
            'redirect_uri' => $this->redirectUri(),
            'scope' => $this->scope(),
        ];
    }

    private function accessToken(): string
    {
        $cached = Cache::get($this->accessCacheKey());
        if (is_string($cached) && $cached !== '') {
            return $cached;
        }

        $refresh = $this->storedRefreshToken();
        if ($refresh === null) {
            throw new ApiException(
                ErrorCode::GOOGLE_NOT_CONNECTED,
                'Google Meet is not connected. An admin must authorize Google first.',
                503,
            );
        }

        $response = Http::asForm()->acceptJson()->post('https://oauth2.googleapis.com/token', [
            'client_id' => config('google.meet.client_id'),
            'client_secret' => config('google.meet.client_secret'),
            'refresh_token' => $refresh,
            'grant_type' => 'refresh_token',
        ]);

        $token = $response->json('access_token');
        if (! $response->successful() || ! is_string($token) || $token === '') {
            Log::error('Google OAuth refresh failed.', [
                'status' => $response->status(),
                'body' => $response->json(),
            ]);
            throw new ApiException(
                ErrorCode::GOOGLE_NOT_CONNECTED,
                'Google authorization expired. Please reconnect Google Meet.',
                503,
            );
        }

        $this->cacheAccessToken($token, (int) ($response->json('expires_in') ?? 3500));

        return $token;
    }

    private function storedRefreshToken(): ?string
    {
        $token = GoogleOAuthToken::query()->where('purpose', GoogleOAuthToken::PURPOSE_MEET)->first();
        $value = $token?->refresh_token;

        return is_string($value) && $value !== '' ? $value : null;
    }

    private function cacheAccessToken(string $token, int $expiresIn): void
    {
        Cache::put($this->accessCacheKey(), $token, now()->addSeconds(max(60, $expiresIn - 60)));
    }

    private function accessCacheKey(): string
    {
        return 'google.meet.access_token';
    }

    private function emailFromAccessToken(?string $accessToken): ?string
    {
        if (! filled($accessToken)) {
            return null;
        }

        $response = Http::withToken($accessToken)->acceptJson()->get('https://www.googleapis.com/oauth2/v2/userinfo');
        $email = $response->json('email');

        return $response->successful() && is_string($email) ? $email : null;
    }

    private function redirectUri(): string
    {
        $configured = trim((string) config('google.meet.redirect_uri'));
        if ($configured !== '') {
            return $configured;
        }

        return rtrim((string) config('app.url'), '/').'/auth/google/callback';
    }

    private function scope(): string
    {
        return (string) config('google.meet.scope', 'https://www.googleapis.com/auth/meetings.space.created');
    }

    private function assertClientConfigured(): void
    {
        if (! filled(config('google.meet.client_id')) || ! filled(config('google.meet.client_secret'))) {
            throw new ApiException(
                ErrorCode::GOOGLE_NOT_CONNECTED,
                'Google OAuth client is not configured on the server.',
                503,
            );
        }
    }

    private function createFailed(): ApiException
    {
        return new ApiException(
            ErrorCode::MEETING_CREATE_FAILED,
            'Unable to create the meeting right now. Please try again.',
            503,
        );
    }

    public static function newState(): string
    {
        return Str::random(40);
    }
}
