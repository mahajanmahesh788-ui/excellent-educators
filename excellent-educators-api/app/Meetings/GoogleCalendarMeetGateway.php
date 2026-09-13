<?php

namespace App\Meetings;

use App\Exceptions\ApiException;
use App\Models\TeacherProfile;
use App\Support\ErrorCode;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Throwable;

class GoogleCalendarMeetGateway implements GoogleMeetGateway
{
    public function createDailyMeet(TeacherProfile $teacher, string $date): CreatedGoogleMeet
    {
        try {
            $token = $this->accessToken();
            $calendarId = rawurlencode((string) config('google.meet.calendar_id', 'primary'));
            $requestId = (string) Str::ulid();
            $response = Http::withToken($token)
                ->acceptJson()
                ->post("https://www.googleapis.com/calendar/v3/calendars/{$calendarId}/events?conferenceDataVersion=1", [
                    'summary' => 'Excellent Educators · '.$teacher->full_name.' · '.$date,
                    'description' => 'Daily Google Meet for this teacher on '.$date.'. All sessions this day use the same room.',
                    'start' => [
                        'dateTime' => $date.'T06:00:00',
                        'timeZone' => (string) config('app.timezone'),
                    ],
                    'end' => [
                        'dateTime' => $date.'T20:00:00',
                        'timeZone' => (string) config('app.timezone'),
                    ],
                    'conferenceData' => [
                        'createRequest' => [
                            'requestId' => $requestId,
                            'conferenceSolutionKey' => [
                                'type' => 'hangoutsMeet',
                            ],
                        ],
                    ],
                ]);

            if (! $response->successful()) {
                Log::error('Google Calendar Meet create failed.', [
                    'status' => $response->status(),
                    'body' => $response->json(),
                    'teacher_id' => $teacher->id,
                    'date' => $date,
                ]);
                throw $this->userError();
            }

            $json = $response->json() ?? [];
            $entry = $json['conferenceData']['entryPoints'] ?? [];
            $meetUrl = null;
            foreach ($entry as $point) {
                if (($point['entryPointType'] ?? '') === 'video' && filled($point['uri'] ?? null)) {
                    $meetUrl = (string) $point['uri'];
                    break;
                }
            }
            $hangout = $json['hangoutLink'] ?? null;
            $meetUrl = $meetUrl ?: (is_string($hangout) ? $hangout : null);

            if (! filled($meetUrl)) {
                Log::error('Google Calendar Meet response missing URL.', [
                    'event_id' => $json['id'] ?? null,
                    'teacher_id' => $teacher->id,
                    'date' => $date,
                ]);
                throw $this->userError();
            }

            return new CreatedGoogleMeet(
                meetUrl: $meetUrl,
                googleEventId: isset($json['id']) ? (string) $json['id'] : null,
                googleMeetingSpaceId: isset($json['conferenceData']['conferenceId'])
                    ? (string) $json['conferenceData']['conferenceId']
                    : null,
            );
        } catch (ApiException $exception) {
            throw $exception;
        } catch (Throwable $exception) {
            Log::error('Google Meet creation threw.', [
                'message' => $exception->getMessage(),
                'teacher_id' => $teacher->id,
                'date' => $date,
            ]);
            throw $this->userError();
        }
    }

    private function accessToken(): string
    {
        $credentials = $this->serviceAccount();
        $now = time();
        $header = $this->b64(json_encode(['alg' => 'RS256', 'typ' => 'JWT'], JSON_THROW_ON_ERROR));
        $payload = $this->b64(json_encode([
            'iss' => $credentials['client_email'],
            'scope' => 'https://www.googleapis.com/auth/calendar https://www.googleapis.com/auth/calendar.events',
            'aud' => 'https://oauth2.googleapis.com/token',
            'iat' => $now,
            'exp' => $now + 3600,
            'sub' => (string) config('google.meet.workspace_user'),
        ], JSON_THROW_ON_ERROR));
        $unsigned = $header.'.'.$payload;
        $key = openssl_pkey_get_private((string) $credentials['private_key']);
        if ($key === false) {
            throw $this->userError();
        }
        $signature = '';
        openssl_sign($unsigned, $signature, $key, OPENSSL_ALGO_SHA256);
        $jwt = $unsigned.'.'.$this->b64($signature);

        $response = Http::asForm()->post('https://oauth2.googleapis.com/token', [
            'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion' => $jwt,
        ]);

        $token = $response->json('access_token');
        if (! $response->successful() || ! is_string($token) || $token === '') {
            Log::error('Google OAuth token failed.', ['status' => $response->status(), 'body' => $response->json()]);
            throw $this->userError();
        }

        return $token;
    }

    /**
     * @return array{client_email: string, private_key: string}
     */
    private function serviceAccount(): array
    {
        $raw = (string) config('google.meet.service_account');
        $path = (string) config('google.meet.service_account_path');
        if ($raw === '' && $path !== '' && is_file($path)) {
            $raw = (string) file_get_contents($path);
        }
        $decoded = json_decode($raw, true);
        if (! is_array($decoded) || empty($decoded['client_email']) || empty($decoded['private_key'])) {
            Log::error('Google service account is not configured.');
            throw $this->userError();
        }
        if (! filled(config('google.meet.workspace_user'))) {
            Log::error('GOOGLE_WORKSPACE_USER is not configured.');
            throw $this->userError();
        }

        return [
            'client_email' => (string) $decoded['client_email'],
            'private_key' => (string) $decoded['private_key'],
        ];
    }

    private function b64(string $value): string
    {
        return rtrim(strtr(base64_encode($value), '+/', '-_'), '=');
    }

    private function userError(): ApiException
    {
        return new ApiException(
            ErrorCode::MEETING_CREATE_FAILED,
            'Unable to create the meeting right now. Please try again.',
            503,
        );
    }
}
