<?php

namespace Utd\Moment\Transformers;

use App\Contracts\GiftDirectory;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Auth;

class MomentResource extends JsonResource
{
    public function toArray($request)
    {
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
            'created_at'  => $this->created_at,
            'updated_at'  => $this->updated_at ?? '',
            'img'         => $this->img ?? '',
            'is_like'     => (bool) ($this->likes_exists ?? false),
            'images'      => $this->images,
            'user'        => $this->whenLoaded('user') ? new UserResource($this->whenLoaded('user')) : [],
        ];
    }
}
