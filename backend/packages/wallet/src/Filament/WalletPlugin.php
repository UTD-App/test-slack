<?php

namespace Utd\Wallet\Filament;

use Filament\Contracts\Plugin;
use Filament\Panel;

/**
 * Filament plugin for the Wallet package. Register by hand in AdminPanelProvider
 * (manual install — see INSTALL.md):
 *
 *   ->plugin(\Utd\Wallet\Filament\WalletPlugin::make())
 */
class WalletPlugin implements Plugin
{
    public function getId(): string
    {
        return 'utd-wallet';
    }

    public function register(Panel $panel): void
    {
        $panel->discoverResources(
            in: __DIR__ . '/Resources',
            for: 'Utd\\Wallet\\Filament\\Resources',
        );
    }

    public function boot(Panel $panel): void
    {
        //
    }

    public static function make(): static
    {
        return new static();
    }
}
