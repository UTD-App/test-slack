<?php

namespace Utd\Reels\Transformers;

use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Auth;

class RealsResource extends JsonResource
{
    public function toArray($request)
    {
        // Raw attribute bag — used to detect the feed's pre-computed reaction data
        // (`*_pre`). array_key_exists (not isset) so a legit null my_reaction still
        // counts as "present" and skips the per-reel fallback query.
        $attrs = $this->resource->getAttributes();

        return [
            'id'             => $this->id ?? 0,
            'user_id'        => $this->user_id ?? 0,
            // True when the requesting user authored this reel — drives the client's
            // delete-button visibility (delete is owner-only).
            'is_owner'       => Auth::id() !== null && (int) Auth::id() === (int) ($this->user_id ?? 0),
            'description'    => $this->description ?? '',
            // Resolved to absolute URLs (e.g. GCS) so video/poster load on every
            // device; passthrough for already-absolute URLs (seeded sample videos).
            'url'            => $this->mediaUrl($this->url),
            'sub_video'      => $this->mediaUrl($this->sub_video),
            // Poster frame written by FfmpegService to the gcs disk (env-prefixed
            // off production). Computed from the id — not a DB column.
            'sub_frame'      => $this->mediaUrl((config('app.env') != 'production' ? '' : 'test-') . 'frames/' . ($this->id ?? 0) . '.jpg'),
            'created_at'     => $this->created_at,
            'updated_at'     => $this->updated_at,
            // Read from the denormalized counter columns (maintained by the
            // like/comment/view services); fall back to a withCount alias if one
            // is ever present. Output keys are unchanged for the client.
            'likes_count'    => (int) ($this->like_num ?? $this->likes_count ?? 0),
            'comments_count' => (int) ($this->comment_num ?? $this->comments_count ?? 0),
            'views_count'    => (int) ($this->view_num ?? $this->views_count ?? 0),
            'likes_exists'   => (bool) ($this->likes_exists ?? false),
            // The current user's reaction type (null if none) + a per-type
            // breakdown for the feed's reaction summary. likes_count above is the
            // total. Feeds pre-compute these once per page (ReelsRepository
            // ::hydrateReactions → `*_pre`); otherwise (single-reel show) we fall
            // back to one small query each.
            'my_reaction'    => array_key_exists('my_reaction_pre', $attrs)
                ? $attrs['my_reaction_pre']
                : (Auth::id() ? $this->likes()->where('user_id', Auth::id())->value('reaction_type') : null),
            'reactions'      => array_key_exists('reactions_pre', $attrs)
                ? $attrs['reactions_pre']
                : $this->likes()
                    ->selectRaw('reaction_type, COUNT(*) as c')
                    ->groupBy('reaction_type')
                    ->pluck('c', 'reaction_type'),
            'share_count'    => (int) ($this->share_num ?? 0),
            'user'           => $this->whenLoaded('user') ? new UserResource($this->whenLoaded('user')) : [],
        ];
    }

    /** Resolve a stored media path to an absolute URL (passthrough for absolute URLs, '' for empty). */
    private function mediaUrl(?string $path): string
    {
        if ($path === null || $path === '') {
            return '';
        }
        if (str_starts_with($path, 'http://') || str_starts_with($path, 'https://')) {
            return $path;
        }
        return \App\Facades\Media::url($path);
    }
}
