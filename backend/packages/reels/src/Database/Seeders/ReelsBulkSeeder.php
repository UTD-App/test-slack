<?php

namespace Utd\Reels\Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;
use Illuminate\Support\Str;
use Utd\Reels\Entities\Real;
use Utd\Reels\Entities\RealUserComment;
use Utd\Reels\Entities\RealUserLike;
use Utd\Reels\Entities\RealUserView;

/**
 * Bulk data for the Reels package — creates 100 reels with public sample videos,
 * random likes, comments and views spread across the available users, with
 * realistic (descending) timestamps so the feed looks populated.
 *
 * Run:  php artisan db:seed --class="Utd\Reels\Database\Seeders\ReelsBulkSeeder"
 */
class ReelsBulkSeeder extends Seeder
{
    /** How many reels to create (the feed needs a healthy backlog). */
    private const COUNT = 100;

    /**
     * Reel videos — every clip below was VERIFIED (2026-06) to be (a) reachable
     * (HTTP 200, video/mp4) and (b) carrying a real audio track (the MP4 has an
     * `mp4a`/`soun` audio stream), so every seeded reel plays WITH SOUND. Kept
     * small/medium so they start fast with no heavy buffering. Spread across four
     * hosts (W3Schools, MDN, samplelib, filesamples) for resilience. Reels cycle
     * through these (`$i % count`) so no two ADJACENT reels share a clip.
     *
     * NOTE: media.w3.org and Google's gtv-videos bucket were dropped — they now
     * return 403 from some networks (incl. this one), so they're not reliable.
     */
    private const SAMPLE_VIDEOS = [
        'https://www.w3schools.com/html/movie.mp4',                                       // 0.3 MB
        'https://www.w3schools.com/html/mov_bbb.mp4',                                     // 0.8 MB
        'https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4',       // 1.1 MB
        'https://samplelib.com/lib/preview/mp4/sample-5s.mp4',                            // 2.7 MB
        'https://samplelib.com/lib/preview/mp4/sample-10s.mp4',                           // 5.2 MB
        'https://samplelib.com/lib/preview/mp4/sample-20s.mp4',                           // 11.3 MB
        'https://samplelib.com/lib/preview/mp4/sample-15s.mp4',                           // 11.4 MB
        'https://filesamples.com/samples/video/mp4/sample_960x400_ocean_with_audio.mp4',  // 16.7 MB
        'https://samplelib.com/lib/preview/mp4/sample-30s.mp4',                           // 20.7 MB
    ];

    public function run(): void
    {
        $users   = $this->ensureUsers();
        $userIds = $users->pluck('id')->all();

        $descriptions = [
            'أول ريل لنا على المنصة الجديدة 🎬',
            'يوم جميل وطاقة إيجابية ☀️',
            'جرّبوا الميزة الجديدة وقولولي رأيكم',
            'Good vibes only ✨',
            'لقطة من رحلتي الأخيرة 📸',
            'شكراً لكل المتابعين ❤️',
            'آخر لحظة قبل النوم 🌙',
            'في انتظار العطلة 🏖️',
            'إنجاز جديد اليوم 💪',
            'موسيقى هادئة وكتاب جميل 🎵📚',
            'Keep pushing forward 🚀',
            'تمرين الصباح خلّص ✅',
            'لحظة امتنان 🙏',
            'New beginnings 🌱',
            'مساء الخير على الجميع 🌆',
        ];

        $comments = [
            'ريل رائع 👍',
            'ما شاء الله 🌟',
            'استمر يا بطل!',
            'Love this ❤️',
            'لقطة جميلة جداً',
            'Nice one 👌',
            'متابع من البداية',
            'Amazing 🔥',
        ];

        $created = 0;

        for ($i = 0; $i < self::COUNT; $i++) {
            $authorId = $userIds[array_rand($userIds)];

            // Spread timestamps over the last while, newest first.
            $createdAt = Carbon::now()->subMinutes($i * random_int(5, 60));

            $real = Real::create([
                'user_id'     => $authorId,
                'url'         => self::SAMPLE_VIDEOS[$i % count(self::SAMPLE_VIDEOS)],
                'description' => $descriptions[array_rand($descriptions)] . ' #' . ($i + 1),
                'sub_video'   => null,
                'share_num'   => random_int(0, 50),
                'created_at'  => $createdAt,
                'updated_at'  => $createdAt,
            ]);

            // Random likes from other users (no duplicates).
            $likers = collect($userIds)
                ->reject(fn ($id) => $id === $authorId)
                ->shuffle()
                ->take(random_int(0, max(0, count($userIds) - 1)));

            foreach ($likers as $likerId) {
                RealUserLike::firstOrCreate([
                    'real_id' => $real->id,
                    'user_id' => $likerId,
                ], [
                    'created_at' => $createdAt,
                    'updated_at' => $createdAt,
                ]);
            }

            // 0–5 comments from random users.
            $commentCount = random_int(0, 5);
            for ($c = 0; $c < $commentCount; $c++) {
                RealUserComment::create([
                    'real_id'    => $real->id,
                    'user_id'    => $userIds[array_rand($userIds)],
                    'comment'    => $comments[array_rand($comments)],
                    'created_at' => $createdAt,
                    'updated_at' => $createdAt,
                ]);
            }

            // 0–20 views from random users.
            $viewCount = random_int(0, 20);
            for ($v = 0; $v < $viewCount; $v++) {
                RealUserView::create([
                    'real_id'            => $real->id,
                    'user_id'            => $userIds[array_rand($userIds)],
                    'duration_in_minute' => random_int(0, 3),
                    'created_at'         => $createdAt,
                    'updated_at'         => $createdAt,
                ]);
            }

            // Keep the denormalized counters consistent (the feed reads these
            // columns, not withCount subqueries).
            $real->update([
                'like_num'    => $likers->count(),
                'comment_num' => $commentCount,
                'view_num'    => $viewCount,
            ]);

            $created++;
        }

        $this->command?->info("Seeded {$created} reels (with random likes, comments & views) across " . count($userIds) . ' users.');
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
                'name'     => "Reels Demo {$n}",
                'email'    => "reels.demo{$n}@example.com",
                'phone'    => '0100000000' . str_pad((string) $n, 2, '0', STR_PAD_LEFT),
                'password' => 'password',
                'uuid'     => (string) Str::uuid(),
                'status'   => true,
            ]);
        }

        return User::query()->orderBy('id')->take(10)->get();
    }
}
