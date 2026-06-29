<?php

namespace App\Console;

use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Foundation\Console\Kernel as ConsoleKernel;

class Kernel extends ConsoleKernel
{
    protected function schedule(Schedule $schedule): void
    {
        // Monthly financial rollover (agencies + users): carry target into
        // old_usd and zero the period counters + coins (see routes/console.php).
        // onOneServer + withoutOverlapping so a multi-server cron can never
        // double-apply it — requires a shared lock-capable cache (redis) in prod.
        $schedule->command('monthly_update')
            ->monthlyOn(1, '00:05')
            ->onOneServer()
            ->withoutOverlapping();

        // Housekeeping: keep the failed-jobs and Telescope tables bounded.
        $schedule->command('queue:prune-failed --hours=168')->daily();
        $schedule->command('telescope:prune --hours=48')->daily();
    }

    protected function commands(): void
    {
        $this->load(__DIR__ . '/Commands');

        require base_path('routes/console.php');
    }
}
