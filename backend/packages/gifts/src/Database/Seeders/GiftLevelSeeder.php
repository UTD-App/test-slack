<?php

namespace Utd\Gifts\Database\Seeders;

use Illuminate\Database\Seeder;
use Utd\Gifts\Models\GiftLevel;

/**
 * Starter sender/receiver level badges so the system is testable out of the box.
 * Run: php artisan db:seed --class="Utd\\Gifts\\Database\\Seeders\\GiftLevelSeeder"
 *
 * Thresholds are in EXP: sender EXP comes from coins spent, receiver EXP from
 * diamonds earned (both via the admin-tunable rates — see GiftExpSettings).
 */
class GiftLevelSeeder extends Seeder
{
    private const ICON = 'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/';

    public function run(): void
    {
        $sender = [
            [1, 0,       'Bronze',  'برونزي', '1f949', '#CD7F32'],
            [2, 1000,    'Silver',  'فضي',    '1f948', '#C0C0C0'],
            [3, 10000,   'Gold',    'ذهبي',   '1f947', '#FFD700'],
            [4, 100000,  'Crown',   'تاج',    '1f451', '#9B59B6'],
            [5, 1000000, 'Legend',  'أسطورة', '1f3c6', '#E74C3C'],
        ];

        $receiver = [
            [1, 0,       'Star',     'نجمة',   '2b50',  '#F1C40F'],
            [2, 1000,    'Shine',    'لمعان',  '1f31f', '#F39C12'],
            [3, 10000,   'Gem',      'جوهرة',  '1f48e', '#3498DB'],
            [4, 100000,  'Heart',    'قلب',    '2764',  '#E74C3C'],
            [5, 1000000, 'Phoenix',  'عنقاء',  '1f525', '#E67E22'],
        ];

        $this->seed(GiftLevel::KIND_SENDER, $sender);
        $this->seed(GiftLevel::KIND_RECEIVER, $receiver);
    }

    private function seed(string $kind, array $rows): void
    {
        foreach ($rows as [$level, $threshold, $en, $ar, $code, $color]) {
            GiftLevel::updateOrCreate(
                ['kind' => $kind, 'level' => $level],
                [
                    'threshold' => $threshold,
                    'title'     => ['en' => $en, 'ar' => $ar],
                    'img'       => self::ICON . $code . '.png',
                    'color'     => $color,
                ],
            );
        }
    }
}
