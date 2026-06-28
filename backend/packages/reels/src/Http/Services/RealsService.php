<?php

namespace Utd\Reels\Http\Services;

use App\Contracts\MediaUploader;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Auth;
use Utd\Reels\Entities\Real;
use Utd\Reels\Entities\RealCategory;
use Utd\Reels\Entities\ReportReals;
use Utd\Reels\Http\Repositories\ReelsRepository;
use Utd\Reels\Jobs\ProcessReelVideo;

class RealsService extends ReelsBaseModelService
{
    public function __construct(Real $model, public ReelsRepository $reelsRepository)
    {
        parent::__construct($model);
    }

    // ── Feed reads (delegated to the repository) ───────────────────────────

    public function getFeed(int $currentUserId, ?string $filter = null, ?int $seed = null)
    {
        // NOTE(gap): the 'following' filter needs the Follow graph (not in Base).
        if ($filter === 'following') {
            return $this->reelsRepository->getFollowedReels($currentUserId, $seed);
        }

        return $this->reelsRepository->getAllReels($currentUserId, $seed);
    }

    public function getUserReals($userId, int $currentUserId)
    {
        return $this->reelsRepository->getUserReals($userId, $currentUserId);
    }

    public function getFollowersFeed(int $currentUserId)
    {
        return $this->reelsRepository->getFollowedReels($currentUserId);
    }

    public function showReal(int $realId, ?int $userId)
    {
        return $this->reelsRepository->getReelById($realId, $userId);
    }

    // ── Writes ─────────────────────────────────────────────────────────────

    /**
     * Create a reel: upload the raw video via the Base MediaUploader, persist the
     * row, then extract a poster frame with FFMpeg (best-effort).
     *
     * NOTE(gap): Eagle also produced an animated GIF preview (`sub_video`) via a
     * Python script — dropped here (sub_video = null). See NOTES_GAPS.md.
     */
    public function create(array $data, int $userId): ?Real
    {
        $file = $data['video'] ?? null;
        if (! $file instanceof UploadedFile || ! $file->isValid()) {
            return null;
        }

        $result = app(MediaUploader::class)->upload($file, 'videos');

        $real = Real::create([
            'user_id'     => $userId,
            'url'         => $result->path,
            'description' => $data['description'] ?? '',
            'sub_video'   => null,
        ]);

        $this->extractFrame($result->url, $real->id);
        $this->syncCategories($real, $data['categories'] ?? null);

        // Optimise the video (faststart + size cap) after the response is sent so
        // playback starts instantly without blocking the upload. See ProcessReelVideo.
        ProcessReelVideo::dispatchAfterResponse($real->id);

        return $real;
    }

    public function update($reelId, array $data): ?Real
    {
        $reel = Real::find($reelId);
        if (! $reel) {
            return null;
        }

        // Ownership guard — only the author may edit via the API.
        if ((int) $reel->user_id !== (int) Auth::id()) {
            return null;
        }

        $update = [];

        $newVideo = false;
        $file = $data['video'] ?? null;
        if ($file instanceof UploadedFile && $file->isValid()) {
            $result = app(MediaUploader::class)->upload($file, 'videos');
            $update['url'] = $result->path;
            $update['sub_video'] = null;
            $this->extractFrame($result->url, $reel->id);
            $newVideo = true;
        }

        if (isset($data['description'])) {
            $update['description'] = $data['description'];
        }

        if (! empty($update)) {
            $reel->update($update);
        }

        $this->syncCategories($reel, $data['categories'] ?? null);

        // Only re-optimise when the video itself changed (caption-only edits skip it).
        if ($newVideo) {
            ProcessReelVideo::dispatchAfterResponse($reel->id);
        }

        return $reel;
    }

    public function delete(int|Real $real): bool
    {
        if (is_int($real)) {
            $real = Real::find($real);
        }

        if (! $real) {
            return false;
        }

        // Ownership guard — admins delete through the Filament ReelResource.
        if ((int) Auth::id() !== (int) $real->user_id) {
            return false;
        }

        $real->delete();

        return true;
    }

    public function deleteReeltAndReport($reelId, $reportId): array
    {
        $reel = Real::find($reelId);
        if (! $reel) {
            return ['success' => false, 'message' => __('reels::messages.not_found'), 'status' => 404];
        }

        $report = ReportReals::find($reportId);
        if ($report) {
            $report->delete();
        }

        $reel->delete();

        return ['success' => true, 'message' => __('reels::messages.report_deleted'), 'status' => 200];
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    /**
     * Generate the poster frame. Never fail reel creation if the ffmpeg binary is
     * missing on the host (see NOTES_GAPS — ffmpeg host prereq).
     */
    private function extractFrame(string $videoUrl, int $realId): void
    {
        try {
            (new FfmpegService())->extract($videoUrl, $realId);
        } catch (\Throwable) {
            // best-effort
        }
    }

    /**
     * Replace the reel's category pivot rows. Done manually (not via a
     * belongsToMany sync) because the Base has no `interests` catalog/model to
     * point the relation at. See NOTES_GAPS.md.
     */
    private function syncCategories(Real $real, $categoryIds): void
    {
        if (! is_array($categoryIds)) {
            return;
        }

        RealCategory::where('real_id', $real->id)->delete();

        foreach (array_unique(array_filter($categoryIds)) as $categoryId) {
            RealCategory::create([
                'real_id'     => $real->id,
                'category_id' => (int) $categoryId,
            ]);
        }
    }
}
