<?php

namespace Utd\Moment\Transformers;

use Carbon\Carbon;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Minimal user payload for moment feeds.
 *
 * NOTE(gap): Eagle's UserResource exposed a large streaming profile (special id,
 * sender/received/charge levels, vip, frames, room presence, chat ids, follow/
 * friend flags) sourced from packages that aren't migrated yet. Reduced to the
 * Base User shape. See NOTES_GAPS.md → "rich user payload".
 */
class UserResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id'     => $this->id,
            'uuid'   => $this->uuid ?? '',
            'name'   => $this->name ?: '',
            'image'  => $this->avatar ?: ($this->profile?->avatar ?: ''),
            'gender' => $this->gender ?? 1,
            'age'    => $this->profile?->birthday ? Carbon::parse($this->profile->birthday)->age : null,
        ];
    }
}
