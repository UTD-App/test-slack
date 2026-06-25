<?php

namespace Utd\Moment\Database\Seeders;

use App\Models\PackageSetting;
use Illuminate\Database\Seeder;

/**
 * Theme / customization seed for the Moment package.
 * Registers the package's customization options in `package_settings` (the Theme
 * Engine reads these for the no-code customization panel + the Flutter app).
 *
 * Run manually after install:  php artisan db:seed --class="Utd\Moment\Database\Seeders\MomentDatabaseSeeder"
 */
class MomentDatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $settings = [
            [
                'package'       => 'moment',
                'key'           => 'moment.feed.enabled',
                'type'          => 'bool',
                'default_value' => true,
                'label_key'     => 'moment.settings.feed_enabled',
            ],
            [
                'package'       => 'moment',
                'key'           => 'moment.card.show_gifts',
                'type'          => 'bool',
                'default_value' => true,
                'label_key'     => 'moment.settings.show_gifts',
            ],
            [
                'package'       => 'moment',
                'key'           => 'moment.feed.page_size',
                'type'          => 'int',
                'default_value' => 10,
                'label_key'     => 'moment.settings.page_size',
            ],
        ];

        foreach ($settings as $setting) {
            PackageSetting::updateOrCreate(['key' => $setting['key']], $setting);
        }
    }
}
