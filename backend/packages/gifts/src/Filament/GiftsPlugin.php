<?php

namespace Utd\Gifts\Filament;

use Filament\Contracts\Plugin;
use Filament\Panel;

/**
 * Filament plugin for the Gifts package. Register by hand in AdminPanelProvider
 * (manual install — see INSTALL.md):
 *
 *   ->plugin(\Utd\Gifts\Filament\GiftsPlugin::make())
 */
class GiftsPlugin implements Plugin
{
    public function getId(): string
    {
        return 'utd-gifts';
    }

    public function register(Panel $panel): void
    {
        $panel->discoverResources(
            in: __DIR__ . '/Resources',
            for: 'Utd\\Gifts\\Filament\\Resources',
        );

        $panel->discoverPages(
            in: __DIR__ . '/Pages',
            for: 'Utd\\Gifts\\Filament\\Pages',
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
