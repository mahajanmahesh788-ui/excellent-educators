<?php

namespace App\Http\Controllers;

use App\Exceptions\ApiException;
use App\Meetings\GoogleMeetService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;
use Symfony\Component\HttpFoundation\Response;

class GoogleOAuthController extends Controller
{
    public function __construct(private readonly GoogleMeetService $googleMeet) {}

    public function redirect(Request $request): RedirectResponse
    {
        $this->assertCanStart($request);
        $state = GoogleMeetService::newState();
        $this->googleMeet->rememberState($state);
        $request->session()->put('google_oauth_state', $state);

        return redirect()->away($this->googleMeet->authorizationUrl($state));
    }

    public function callback(Request $request): View|Response
    {
        $error = $request->string('error')->toString();
        if ($error !== '') {
            return response()->view('google.oauth-result', [
                'ok' => false,
                'title' => 'Google authorization cancelled',
                'message' => 'Google did not grant access. Ask an admin to connect Google Meet again.',
            ], 400);
        }

        $state = $request->string('state')->toString();
        $sessionState = (string) $request->session()->pull('google_oauth_state');
        $valid = $this->googleMeet->consumeState($state)
            || ($sessionState !== '' && hash_equals($sessionState, $state));
        if (! $valid) {
            return response()->view('google.oauth-result', [
                'ok' => false,
                'title' => 'Invalid Google callback',
                'message' => 'This Google login link expired. In Admin → Google Meet, click Connect Google again.',
            ], 400);
        }

        $code = $request->string('code')->toString();
        if ($code === '') {
            return response()->view('google.oauth-result', [
                'ok' => false,
                'title' => 'Missing authorization code',
                'message' => 'Google did not return an authorization code.',
            ], 400);
        }

        try {
            $this->googleMeet->completeAuthorization($code);
        } catch (ApiException $exception) {
            return response()->view('google.oauth-result', [
                'ok' => false,
                'title' => 'Google authorization failed',
                'message' => $exception->getMessage(),
            ], $exception->getStatusCode());
        }

        return view('google.oauth-result', [
            'ok' => true,
            'title' => 'Google Meet connected',
            'message' => 'Refresh token saved on the server. Bookings can now create one Meet link per teacher and date.',
        ]);
    }

    private function assertCanStart(Request $request): void
    {
        if (app()->environment(['local', 'testing']) || $request->hasValidSignature()) {
            return;
        }

        abort(403, 'Use a signed Google connect URL from php artisan google:connect.');
    }
}
