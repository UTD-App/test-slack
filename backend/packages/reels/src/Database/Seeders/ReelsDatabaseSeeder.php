<?php

namespace Utd\Reels\Database\Seeders;

use App\Models\PackageSetting;
use Illuminate\Database\Seeder;

/**
 * Theme / customization seed for the Reels package.
 * Registers the package's customization options in `package_settings` (the Theme
 * Engine reads these for the no-code customization panel + the Flutter app).
 *
 * Run manually after install:  php artisan db:seed --class="Utd\Reels\Database\Seeders\ReelsDatabaseSeeder"
 */
class ReelsDatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $settings = [
            [
                'package'       => 'reels',
                'key'           => 'reels.feed.enabled',
                'type'          => 'bool',
                'default_value' => true,
                'label_key'     => 'reels.settings.feed_enabled',
            ],
            [
                'package'       => 'reels',
                'key'           => 'reels.card.show_gifts',
                'type'          => 'bool',
                'default_value' => true,
                'label_key'     => 'reels.settings.show_gifts',
            ],
            [
                'package'       => 'reels',
                'key'           => 'reels.feed.page_size',
                'type'          => 'int',
                'default_value' => 10,
                'label_key'     => 'reels.settings.page_size',
            ],
        ];

        foreach ($settings as $setting) {
            PackageSetting::updateOrCreate(['key' => $setting['key']], $setting);
        }
    }
}
