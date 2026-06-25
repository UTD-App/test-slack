<?php

namespace Utd\Moment\Filament;

use Filament\Contracts\Plugin;
use Filament\Panel;

/**
 * Filament plugin for the Moment package.
 *
 * Because this is a standalone (non-module) package, the Base AdminPanelProvider
 * does NOT auto-discover its resources. Register this plugin BY HAND in the panel
 * (manual install) — see INSTALL.md:
 *
 *   ->plugin(\Utd\Moment\Filament\MomentPlugin::make())
 */
class MomentPlugin implements Plugin
{
    public function getId(): string
    {
        return 'utd-moment';
    }

    public function register(Panel $panel): void
    {
        $panel->discoverResources(
            in: __DIR__ . '/Resources',
            for: 'Utd\\Moment\\Filament\\Resources',
        );

        // Facebook-style feed page (the main "Moments" nav item) + any other pages.
        $panel->discoverPages(
            in: __DIR__ . '/Pages',
            for: 'Utd\\Moment\\Filament\\Pages',
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
