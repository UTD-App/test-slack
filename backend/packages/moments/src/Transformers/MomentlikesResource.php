<?php

namespace Utd\Moment\Transformers;

use Illuminate\Http\Resources\Json\JsonResource;

class MomentlikesResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id'         => $this->id,
            'moment_id'  => $this->moment_id,
            'user_id'    => $this->user_id,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
            'user'       => $this->whenLoaded('user') ? new UserResource($this->whenLoaded('user')) : null,
        ];
    }
}
