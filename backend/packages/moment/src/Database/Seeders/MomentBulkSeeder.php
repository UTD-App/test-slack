<?php

namespace Utd\Moment\Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;
use Illuminate\Support\Str;
use Utd\Moment\Entities\Moment;
use Utd\Moment\Entities\MomentComment;
use Utd\Moment\Entities\MomentGallery;
use Utd\Moment\Entities\MomentLikes;

/**
 * Bulk data for the Moment package — creates 100 moments with random images,
 * likes and comments spread across the available users, with realistic
 * (descending) timestamps so the feed looks populated.
 *
 * Unlike MomentDemoSeeder (a tiny fixed handful), this one is for stress / demo
 * scenarios where you want a full feed.
 *
 * Run:  php artisan db:seed --class="Utd\Moment\Database\Seeders\MomentBulkSeeder"
 */
class MomentBulkSeeder extends Seeder
{
    /** How many moments to create. */
    private const COUNT = 100;

    public function run(): void
    {
        $users   = $this->ensureUsers();
        $userIds = $users->pluck('id')->all();

        $descriptions = [
            'أول لحظة لنا على المنصة الجديدة 🎉',
            'يوم جميل وطاقة إيجابية ☀️',
            'جرّبوا الميزة الجديدة وقولولي رأيكم',
            'Good vibes only ✨',
            'لحظة قهوة الصبح ☕',
            'شكراً لكل المتابعين ❤️',
            'آخر لحظة قبل النوم 🌙',
            'في انتظار العطلة 🏖️',
            'إنجاز جديد اليوم 💪',
            'لقطة من رحلتي الأخيرة 📸',
            'موسيقى هادئة وكتاب جميل 🎵📚',
            'Keep pushing forward 🚀',
            'وجبة اليوم كانت رائعة 🍽️',
            'تمرين الصباح خلّص ✅',
            'لحظة امتنان 🙏',
            'Throwback to better days 🕰️',
            'تجربة جديدة تستحق المشاركة',
            'مساء الخير على الجميع 🌆',
            'ابتسامة تكفي ليومك 😊',
            'New beginnings 🌱',
        ];

        $comments = [
            'تعليق رائع 👍',
            'ما شاء الله 🌟',
            'استمر يا بطل!',
            'Love this ❤️',
            'لقطة جميلة جداً',
            'حظ سعيد 🍀',
            'Nice one 👌',
            'متابع من البداية',
            'كلام من ذهب ✨',
            'Amazing 🔥',
        ];

        $created = 0;

        for ($i = 0; $i < self::COUNT; $i++) {
            $authorId = $userIds[array_rand($userIds)];

            // Spread timestamps over the last ~30 days, newest first.
            $createdAt = Carbon::now()->subMinutes($i * random_int(5, 60));

            $moment = Moment::create([
                'user_id'     => $authorId,
                'description' => $descriptions[array_rand($descriptions)] . ' #' . ($i + 1),
                'created_at'  => $createdAt,
                'updated_at'  => $createdAt,
            ]);

            // 0–3 demo images (remote placeholders — the feed view detects full URLs).
            $imgCount = random_int(0, 3);
            for ($n = 1; $n <= $imgCount; $n++) {
                MomentGallery::create([
                    'moment_id'  => $moment->id,
                    'image'      => "https://picsum.photos/seed/moment{$moment->id}-{$n}/800/600",
                    'created_at' => $createdAt,
                    'updated_at' => $createdAt,
                ]);
            }

            // Random likes from other users (no duplicates).
            $likers = collect($userIds)
                ->reject(fn ($id) => $id === $authorId)
                ->shuffle()
                ->take(random_int(0, max(0, count($userIds) - 1)));

            foreach ($likers as $likerId) {
                MomentLikes::firstOrCreate([
                    'moment_id' => $moment->id,
                    'user_id'   => $likerId,
                ]);
            }

            // 0–4 comments from random users.
            $commentCount = random_int(0, 4);
            for ($c = 0; $c < $commentCount; $c++) {
                MomentComment::create([
                    'moment_id'  => $moment->id,
                    'user_id'    => $userIds[array_rand($userIds)],
                    'comment'    => $comments[array_rand($comments)],
                    'created_at' => $createdAt,
                    'updated_at' => $createdAt,
                ]);
            }

            // Keep the denormalized counters consistent.
            $moment->update([
                'like_num'    => $likers->count(),
                'comment_num' => $commentCount,
            ]);

            $created++;
        }

        $this->command?->info("Seeded {$created} moments (with random images, likes & comments) across " . count($userIds) . ' users.');
    }

    /**
     * Use existing users, or create up to 10 demo users so likes/comments have
     * enough variety to spread across.
     */
    private function ensureUsers()
    {
        $existing = User::query()->orderBy('id')->take(10)->get();

        if ($existing->count() >= 5) {
            return $existing;
        }

        for ($i = $existing->count(); $i < 10; $i++) {
            $n = $i + 1;
            User::create([
                'name'     => "Moment Demo {$n}",
                'email'    => "moment.demo{$n}@example.com",
                'phone'    => '0100000000' . str_pad((string) $n, 2, '0', STR_PAD_LEFT),
                'password' => 'password',
                'uuid'     => (string) Str::uuid(),
                'status'   => true,
            ]);
        }

        return User::query()->orderBy('id')->take(10)->get();
    }
}
