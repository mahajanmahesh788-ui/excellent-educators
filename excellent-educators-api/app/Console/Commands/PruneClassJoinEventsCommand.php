<?php

namespace App\Console\Commands;

use App\Attendance\AttendanceService;
use Illuminate\Console\Command;

class PruneClassJoinEventsCommand extends Command
{
    protected $signature = 'attendance:prune-join-events';

    protected $description = 'Delete temporary class join clicks that are not part of a dispute.';

    public function handle(AttendanceService $attendance): int
    {
        $deleted = $attendance->pruneJoinEvents();
        $this->info("Removed {$deleted} join event(s).");

        return self::SUCCESS;
    }
}
