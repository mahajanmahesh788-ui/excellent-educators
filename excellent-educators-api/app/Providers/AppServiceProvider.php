<?php

namespace App\Providers;

use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Auth\Notifications\ResetPassword;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Password as PasswordBroker;
use Illuminate\Support\ServiceProvider;
use Illuminate\Validation\Rules\Password as PasswordRule;
use App\Meetings\FakeGoogleMeetGateway;
use App\Meetings\GoogleCalendarMeetGateway;
use App\Meetings\GoogleMeetGateway;
use App\Meetings\GoogleMeetService;
use App\Models\AttendanceIssue;
use App\Models\MonthlyFeedback;
use App\Policies\AttendanceIssuePolicy;
use App\Policies\MonthlyFeedbackPolicy;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->singleton(GoogleMeetService::class);

        $this->app->singleton(GoogleMeetGateway::class, function ($app) {
            return match ((string) config('google.meet.driver', 'google')) {
                'fake' => new FakeGoogleMeetGateway,
                'calendar' => new GoogleCalendarMeetGateway,
                default => $app->make(GoogleMeetService::class),
            };
        });
    }

    public function boot(): void
    {
        Gate::policy(MonthlyFeedback::class, MonthlyFeedbackPolicy::class);
        Gate::policy(AttendanceIssue::class, AttendanceIssuePolicy::class);

        PasswordRule::defaults(fn () => PasswordRule::min(8));

        ResetPassword::createUrlUsing(function (object $notifiable, string $token): string {
            $base = rtrim((string) config('app.frontend_url'), '/');
            $email = urlencode($notifiable->getEmailForPasswordReset());

            return "{$base}/reset-password?email={$email}&token={$token}";
        });

        RateLimiter::for('auth', function (Request $request) {
            return Limit::perMinute(5)->by($request->ip());
        });
    }
}
