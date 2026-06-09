<?php

namespace App\Filament\Widgets;

use App\Models\User;
use Filament\Widgets\StatsOverviewWidget as BaseWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class StatsOverviewWidget extends BaseWidget
{
    protected function getStats(): array
    {
        return [
            Stat::make(__('admin.total_users'), User::count())
                ->icon('heroicon-o-users')
                ->color('primary'),

            Stat::make(__('admin.active_users'), User::where('status', 1)->count())
                ->icon('heroicon-o-check-circle')
                ->color('success'),

            Stat::make(__('admin.banned_users'), User::where('status', 0)->count())
                ->icon('heroicon-o-no-symbol')
                ->color('danger'),
        ];
    }
}
