<?php

namespace Utd\Moment\Transformers;

use App\Contracts\GiftDirectory;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Auth;

class MomentResource extends JsonResource
{
    public function toArray($request)
    {
        // Raw attribute bag — used to detect the feed's pre-computed reaction data
        // (`*_pre`). array_key_exists (not offsetExists/isset) so a legit null
        // my_reaction still counts as "present" and skips the fallback query.
        $attrs = $this->resource->getAttributes();

        return [
            'id'          => $this->id ?? 0,
            'user_id'     => $this->user_id ?? 0,
            // True when the requesting user authored this moment — drives the
            // client's delete-button visibility (delete is owner-only).
            'is_owner'    => Auth::id() !== null && (int) Auth::id() === (int) ($this->user_id ?? 0),
            'description' => $this->description ?? '',
            'comment_num' => (int) ($this->comments_count ?? 0),
            'like_num'    => (int) ($this->likes_count ?? 0),
            // Real count when the Gifts package is installed (binds GiftDirectory),
            // else 0. NOTE: one small query per moment — fine for paginated feeds.
            'gifts_count' => app()->bound(GiftDirectory::class)
                ? app(GiftDirectory::class)->countFor('moment', (int) ($this->id ?? 0))
                : 0,
            // Sum of coins spent on gifts for this moment (drives the mobile gift
            // counter, shown K-formatted). 0 when the Gifts package is absent.
            'gifts_coins' => app()->bound(GiftDirectory::class)
                ? (float) app(GiftDirectory::class)->coinsFor('moment', (int) ($this->id ?? 0))
                : 0,
            'created_at'  => $this->created_at,
            'updated_at'  => $this->updated_at ?? '',
            'img'         => $this->mediaUrl($this->img),
            'is_like'     => (bool) ($this->likes_exists ?? false),
            // The current user's reaction type (null if none) + a per-type
            // breakdown for the feed's reaction summary. like_num above is the
            // total. Feeds pre-compute these once per page (MomentRepository
            // ::hydrateReactions → `*_pre`); otherwise (single-moment show) we
            // fall back to one small query each.
            'my_reaction' => array_key_exists('my_reaction_pre', $attrs)
                ? $attrs['my_reaction_pre']
                : (Auth::id() ? $this->likes()->where('user_id', Auth::id())->value('reaction_type') : null),
            'reactions'   => array_key_exists('reactions_pre', $attrs)
                ? $attrs['reactions_pre']
                : $this->likes()
                    ->selectRaw('reaction_type, COUNT(*) as c')
                    ->groupBy('reaction_type')
                    ->pluck('c', 'reaction_type'),
            // Each gallery image resolved to an absolute URL (e.g. GCS); a raw path
            // 404s against the local /storage on cloud setups.
            'images'      => $this->images->map(fn ($g) => $this->mediaUrl($g->image))->filter()->values(),
            'user'        => $this->whenLoaded('user') ? new UserResource($this->whenLoaded('user')) : [],
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
