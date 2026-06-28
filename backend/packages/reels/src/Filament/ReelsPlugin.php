<?php

namespace Utd\Reels\Filament;

use Filament\Contracts\Plugin;
use Filament\Panel;

/**
 * Filament plugin for the Reels package.
 *
 * Because this is a standalone (non-module) package, the Base AdminPanelProvider
 * does NOT auto-discover its resources. Register this plugin BY HAND in the panel
 * (manual install) — see INSTALL.md:
 *
 *   ->plugin(\Utd\Reels\Filament\ReelsPlugin::make())
 */
class ReelsPlugin implements Plugin
{
    public function getId(): string
    {
        return 'utd-reels';
    }

    public function register(Panel $panel): void
    {
        $panel->discoverResources(
            in: __DIR__ . '/Resources',
            for: 'Utd\\Reels\\Filament\\Resources',
        );

        // TikTok-style feed page (the main "Reels" nav item) + any other pages.
        $panel->discoverPages(
            in: __DIR__ . '/Pages',
            for: 'Utd\\Reels\\Filament\\Pages',
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
