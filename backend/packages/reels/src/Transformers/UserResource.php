<?php

namespace Utd\Reels\Transformers;

use Carbon\Carbon;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Minimal user payload for reel feeds.
 *
 * NOTE(gap): Eagle's UserResource exposed a large streaming profile (special id,
 * sender/charge levels, vip, room presence, manager type, follow flags) sourced
 * from packages that aren't migrated yet. Reduced to the Base User shape. See
 * NOTES_GAPS.md → "rich user payload".
 */
class UserResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id'     => $this->id,
            'uuid'   => $this->uuid ?? '',
            'name'   => $this->name ?: '',
            // Resolved to an absolute URL (e.g. GCS) so the avatar loads on every
            // device — a raw path would 404 against the local /storage on cloud setups.
            'image'  => $this->mediaUrl($this->avatar ?: ($this->profile?->avatar ?: '')),
            'gender' => $this->gender ?? 1,
            'age'    => $this->profile?->birthday ? Carbon::parse($this->profile->birthday)->age : null,
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
