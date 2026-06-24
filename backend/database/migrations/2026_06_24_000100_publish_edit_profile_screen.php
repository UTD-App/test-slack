<?php

use App\Models\StacScreen;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Schema;

/**
 * Publishes the server-driven `edit_profile` screen into `stac_screens` so the
 * app's `/profile` route (StacDynamicScreen) renders it via UTD Studio instead
 * of going straight to the native form.
 *
 * The edit form is "too rich for Stac primitives" (image pick + upload, multi
 * cover management, save-with-state), so — exactly like the self-profile landing
 * — the screen is a single custom widget node (`core.editProfileForm`, rendered
 * natively by EditProfileFormParser in Flutter). It is NOT in the manifest's
 * `default_screens` on purpose: UTD Studio's Craft editor crashes deserializing
 * an unregistered custom type, so the screen is authored here (the same path the
 * audio-room package uses to write `app_layout`) rather than Studio-seeded. The
 * Flutter route keeps the native form as a fallback until this runs.
 */
return new class extends Migration
{
    private const NAME = 'edit_profile';

    public function up(): void
    {
        if (!Schema::hasTable('stac_screens')) {
            return;
        }

        $content = ['type' => 'core.editProfileForm'];

        StacScreen::updateOrCreate(
            ['name' => self::NAME],
            [
                'package'   => 'core',
                'version'   => substr(md5(json_encode($content)), 0, 12),
                'content'   => $content,
                'is_active' => true,
            ]
        );
    }

    public function down(): void
    {
        if (!Schema::hasTable('stac_screens')) {
            return;
        }

        StacScreen::where('name', self::NAME)->delete();
    }
};
