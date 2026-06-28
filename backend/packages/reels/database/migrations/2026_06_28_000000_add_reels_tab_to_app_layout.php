<?php

use App\Models\StacScreen;
use Illuminate\Database\Migrations\Migration;

/**
 * Adds the Reels tab to the server-driven `app_layout` bottom nav.
 *
 * Reels is a NATIVE feature (a video feed, not a Stac screen), so the tab is
 * `kind: native` and resolves at runtime to ReelsFeature via its `featureId`
 * (`com.utd.reels`): the app shell maps a native tab to the matching
 * UiSlot.bottomNav contribution (see app_shell.dart `_nativeBuilder`). This is
 * how a native package pushes itself into the menu — it mirrors the audio-room
 * `add_rooms_tab_to_app_layout` migration. (Stac-screen packages like moment do
 * the same thing through their `utd_manifest.php` `nav => true` screens instead.)
 *
 * No-op when no `app_layout` document exists (a backend that hasn't been
 * Studio-published yet) — there, the native bottom-nav fallback already shows
 * reels. Idempotent: guarded on featureId so re-running never duplicates the tab.
 */
return new class extends Migration
{
    private const FEATURE_ID = 'com.utd.reels';

    public function up(): void
    {
        if (! class_exists(StacScreen::class)) {
            return;
        }

        $screen = StacScreen::where('name', 'app_layout')->first();
        if (! $screen) {
            return;
        }

        $content = $screen->content;
        $tabs = $content['bottomNav']['tabs'] ?? [];

        foreach ($tabs as $tab) {
            if (($tab['featureId'] ?? '') === self::FEATURE_ID) {
                return; // already present
            }
        }

        $reelsTab = [
            'icon'      => 'video',
            'kind'      => 'native',
            'label'     => 'ريلز',
            'route'     => '/reels',
            'screen'    => 'reels',
            'featureId' => self::FEATURE_ID,
        ];

        // Insert a little way in (after Home + any first feature); an offset
        // beyond the list simply appends, so this is always safe.
        array_splice($tabs, 2, 0, [$reelsTab]);
        $content['bottomNav']['tabs'] = $tabs;

        $screen->update([
            'content' => $content,
            'version' => substr(md5(json_encode($content)), 0, 12),
        ]);
    }

    public function down(): void
    {
        if (! class_exists(StacScreen::class)) {
            return;
        }

        $screen = StacScreen::where('name', 'app_layout')->first();
        if (! $screen) {
            return;
        }

        $content = $screen->content;
        $tabs = $content['bottomNav']['tabs'] ?? [];

        $content['bottomNav']['tabs'] = array_values(
            array_filter($tabs, fn ($t) => ($t['featureId'] ?? '') !== self::FEATURE_ID)
        );

        $screen->update([
            'content' => $content,
            'version' => substr(md5(json_encode($content)), 0, 12),
        ]);
    }
};
