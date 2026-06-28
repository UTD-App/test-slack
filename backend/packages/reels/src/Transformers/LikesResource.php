<?php

namespace Utd\Reels\Transformers;

use Illuminate\Http\Resources\Json\JsonResource;

class LikesResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id'            => $this->id,
            'real_id'       => $this->real_id,
            'user_id'       => $this->user_id,
            'reaction_type' => $this->reaction_type ?? 'like',
            'created_at'    => $this->created_at,
            'updated_at'    => $this->updated_at,
            'user'          => $this->whenLoaded('user') ? new UserResource($this->whenLoaded('user')) : null,
        ];
    }
}
