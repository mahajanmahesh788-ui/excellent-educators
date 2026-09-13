<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\URL;

class ConnectGoogleMeetCommand extends Command
{
    protected $signature = 'google:connect';

    protected $description = 'Print the Google Meet OAuth URL (signed outside local).';

    public function handle(): int
    {
        $url = app()->environment('local')
            ? url('/auth/google/redirect')
            : URL::temporarySignedRoute('google.redirect', now()->addMinutes(20));

        $this->info('Open this URL in a browser while logged into the Google account that should own Meet rooms:');
        $this->line($url);
        $this->newLine();
        $this->comment('Google must redirect to: '.config('google.meet.redirect_uri', url('/auth/google/callback')));

        return self::SUCCESS;
    }
}
