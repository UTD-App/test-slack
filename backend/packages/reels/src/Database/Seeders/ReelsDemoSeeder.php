<?php

namespace Utd\Reels\Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;
use Utd\Reels\Entities\Real;
use Utd\Reels\Entities\RealUserComment;
use Utd\Reels\Entities\RealUserLike;

/**
 * Demo data for the Reels package — creates a handful of reels (with a few likes
 * & comments) so you can try the feed/endpoints quickly. Videos are public sample
 * MP4 URLs (the feed view / Flutter media resolver detect full URLs).
 *
 * Run:  php artisan db:seed --class="Utd\Reels\Database\Seeders\ReelsDemoSeeder"
 */
class ReelsDemoSeeder extends Seeder
{
    /**
     * Reel videos — every clip was VERIFIED (2026-06) to be reachable (HTTP 200,
     * video/mp4) AND to carry a real audio track (MP4 `mp4a`/`soun` stream), so
     * every reel plays with sound. (media.w3.org / Google bucket dropped — they 403
     * from some networks now.) Same pool as ReelsBulkSeeder.
     */
    private const SAMPLE_VIDEOS = [
        'https://www.w3schools.com/html/movie.mp4',
        'https://www.w3schools.com/html/mov_bbb.mp4',
        'https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4',
        'https://samplelib.com/lib/preview/mp4/sample-5s.mp4',
        'https://samplelib.com/lib/preview/mp4/sample-10s.mp4',
        'https://filesamples.com/samples/video/mp4/sample_960x400_ocean_with_audio.mp4',
    ];

    public function run(): void
    {
        $users = $this->ensureUsers();

        $descriptions = [
            'أول ريل لنا على المنصة الجديدة 🎬',
            'جرّبوا الميزة الجديدة وقولولي رأيكم',
            'Good vibes only ✨',
            'لقطة من رحلتي الأخيرة 📸',
            'New beginnings 🌱',
            'لحظة امتنان 🙏',
        ];

        foreach (self::SAMPLE_VIDEOS as $i => $videoUrl) {
            $author = $users[$i % $users->count()];

            $real = Real::create([
                'user_id'     => $author->id,
                'url'         => $videoUrl,
                'description' => $descriptions[$i % count($descriptions)],
                'sub_video'   => null,
            ]);

            // a few likes from other users
            $likeCount = 0;
            foreach ($users as $u) {
                if ($u->id !== $author->id && $u->id % 2 === $i % 2) {
                    RealUserLike::firstOrCreate(['real_id' => $real->id, 'user_id' => $u->id]);
                    $likeCount++;
                }
            }

            // a comment
            $commenter = $users[($i + 1) % $users->count()];
            RealUserComment::create([
                'real_id' => $real->id,
                'user_id' => $commenter->id,
                'comment' => 'تعليق تجريبي على الريل 👍',
            ]);

            // Keep the denormalized counters consistent (the feed reads these
            // columns, not withCount subqueries).
            $real->update(['like_num' => $likeCount, 'comment_num' => 1]);
        }

        $this->command?->info('Seeded ' . count(self::SAMPLE_VIDEOS) . ' reels (with demo likes & comments) across ' . $users->count() . ' users.');
    }

    /** Use existing users, or create 3 demo users if the table is (almost) empty. */
    private function ensureUsers()
    {
        $users = User::query()->orderBy('id')->take(3)->get();

        if ($users->count() >= 2) {
            return $users;
        }

        for ($i = $users->count(); $i < 3; $i++) {
            $n = $i + 1;
            User::create([
                'name'     => "Reels Demo {$n}",
                'email'    => "reels.demo{$n}@example.com",
                'phone'    => '0100000000' . $n,
                'password' => 'password',
                'uuid'     => (string) Str::uuid(),
                'status'   => true,
            ]);
        }

        return User::query()->orderBy('id')->take(3)->get();
    }
}
