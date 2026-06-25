<?php

namespace Utd\Moment\Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;
use Utd\Moment\Entities\Moment;
use Utd\Moment\Entities\MomentCommint;
use Utd\Moment\Entities\MomentGallery;
use Utd\Moment\Entities\MomentLikes;

/**
 * Demo data for the Moment package — creates a handful of moments (with a few
 * likes & comments) so you can try the feed/endpoints quickly.
 *
 * Run:  php artisan db:seed --class="Utd\Moment\Database\Seeders\MomentDemoSeeder"
 */
class MomentDemoSeeder extends Seeder
{
    public function run(): void
    {
        $users = $this->ensureUsers();

        $descriptions = [
            'أول لحظة لنا على المنصة الجديدة 🎉',
            'يوم جميل وطاقة إيجابية ☀️',
            'جرّبوا الميزة الجديدة وقولولي رأيكم',
            'Good vibes only ✨',
            'لحظة قهوة الصبح ☕',
            'شكراً لكل المتابعين ❤️',
            'منشور تجريبي رقم سبعة',
            'آخر لحظة قبل النوم 🌙',
        ];

        // How many demo images each moment gets (by index): 1st → 1 image, 2nd → 2 images.
        $imageCounts = [0 => 1, 1 => 2];

        foreach ($descriptions as $i => $text) {
            $author = $users[$i % $users->count()];

            $moment = Moment::create([
                'user_id'     => $author->id,
                'description' => $text,
            ]);

            // demo images (remote placeholders — the feed view detects full URLs).
            $imgCount = $imageCounts[$i] ?? 0;
            for ($n = 1; $n <= $imgCount; $n++) {
                MomentGallery::create([
                    'moment_id' => $moment->id,
                    'image'     => "https://picsum.photos/seed/moment{$moment->id}-{$n}/800/600",
                ]);
            }

            // a few likes from other users
            foreach ($users as $u) {
                if ($u->id !== $author->id && $u->id % 2 === $i % 2) {
                    MomentLikes::firstOrCreate(['moment_id' => $moment->id, 'user_id' => $u->id]);
                }
            }

            // a comment or two
            $commenter = $users[($i + 1) % $users->count()];
            MomentCommint::create([
                'moment_id' => $moment->id,
                'user_id'   => $commenter->id,
                'comment'   => 'تعليق تجريبي على المنشور 👍',
            ]);
        }

        $this->command?->info('Seeded ' . count($descriptions) . ' moments (with demo images) across ' . $users->count() . ' users.');
    }

    /**
     * Use existing users, or create 3 demo users if the table is (almost) empty.
     */
    private function ensureUsers()
    {
        $users = User::query()->orderBy('id')->take(3)->get();

        if ($users->count() >= 2) {
            return $users;
        }

        for ($i = $users->count(); $i < 3; $i++) {
            $n = $i + 1;
            User::create([
                'name'     => "Moment Demo {$n}",
                'email'    => "moment.demo{$n}@example.com",
                'phone'    => '0100000000' . $n,
                'password' => 'password',
                'uuid'     => (string) Str::uuid(),
                'status'   => true,
            ]);
        }

        return User::query()->orderBy('id')->take(3)->get();
    }
}
