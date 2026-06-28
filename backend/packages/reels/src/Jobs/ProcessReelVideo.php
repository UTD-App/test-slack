<?php

namespace Utd\Reels\Jobs;

use FFMpeg\Format\Video\X264;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use ProtoneMedia\LaravelFFMpeg\Support\FFMpeg;
use Utd\Reels\Entities\Real;

/**
 * Post-process an uploaded reel video so playback STARTS INSTANTLY and streams
 * cheaply at scale. This is the single biggest win for the "it loads before it
 * plays" delay.
 *
 *  - `-movflags +faststart` moves the moov atom to the front of the file so the
 *    player can begin playing while the rest is still downloading. Without it,
 *    video_player/ExoPlayer must pull the WHOLE file before the first frame.
 *  - caps width to 720px and the bitrate to ~2.5 Mbps so a 4K/60fps upload isn't
 *    streamed at full size to every viewer (bandwidth + buffering). Only
 *    downscales — smaller clips are left at their own size.
 *
 * Best-effort: on ANY failure (missing ffmpeg binary, odd codec, reel deleted
 * meanwhile) the ORIGINAL file is left untouched, so the reel still plays — just
 * unoptimised. The reel row is only repointed after a non-empty output exists.
 *
 * Dispatched via dispatchAfterResponse() (see RealsService) so it never blocks
 * the upload response. For high volume, run a real queue worker and switch the
 * caller to ::dispatch() — this class is already ShouldQueue-ready.
 */
class ProcessReelVideo implements ShouldQueue
{
    use Dispatchable;
    use InteractsWithQueue;
    use Queueable;
    use SerializesModels;

    /** Marks an already-optimised file so re-runs are a no-op. */
    private const OPT_MARKER = '.opt.';

    public function __construct(public int $realId) {}

    public function handle(): void
    {
        $real = Real::find($this->realId);
        if (! $real) {
            return;
        }

        $src = ltrim((string) $real->url, '/');

        // Skip absolute URLs (externally hosted) and already-optimised files.
        if ($src === '' || str_starts_with($src, 'http') || str_contains($src, self::OPT_MARKER)) {
            return;
        }

        $disk = config('filesystems.default');
        if (! Storage::disk($disk)->exists($src)) {
            return;
        }

        // Optimised output lives beside the original: videos/<uuid>.opt.mp4
        $dir  = trim(dirname($src), '/.');
        $base = pathinfo($src, PATHINFO_FILENAME);
        $dst  = ($dir !== '' ? $dir.'/' : '').$base.self::OPT_MARKER.'mp4';

        try {
            $format = new X264('aac', 'libx264');
            $format->setKiloBitrate(2500)
                ->setAudioKiloBitrate(128)
                ->setAdditionalParameters([
                    '-movflags', '+faststart',   // instant-start streaming
                    '-preset', 'veryfast',       // keep transcode time/CPU low
                    '-profile:v', 'main',
                    '-pix_fmt', 'yuv420p',       // broad device compatibility
                ]);

            FFMpeg::fromDisk($disk)
                ->open($src)
                ->export()
                ->toDisk($disk)
                // Downscale only when wider than 720px; preserve aspect, force an
                // even height (libx264/yuv420p require even dimensions).
                ->addFilter(['-vf', 'scale=min(720\,iw):-2'])
                ->inFormat($format)
                ->save($dst);

            if (! Storage::disk($disk)->exists($dst) || Storage::disk($disk)->size($dst) <= 0) {
                return; // produced nothing usable — keep the original in place
            }

            // Repoint the reel at the optimised file, then drop the original.
            $old = $real->url;
            $real->update(['url' => $dst]);
            Storage::disk($disk)->delete(ltrim((string) $old, '/'));
        } catch (\Throwable $e) {
            Log::warning("reels: video optimise failed for #{$this->realId}: {$e->getMessage()}");
            // best-effort — the original stays and remains playable.
        }
    }
}
