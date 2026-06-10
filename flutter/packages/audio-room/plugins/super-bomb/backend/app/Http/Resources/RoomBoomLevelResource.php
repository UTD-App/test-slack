<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class RoomBoomLevelResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->id,
            'level' => $this->level,
            'min_target' => $this->whenHas('min_target'),
            'target' => $this->whenHas('target'),
            'video' => $this->video,
            'image_type' => $this->image_type,
            'room_booms' => RoomBoomResource::collection($this->whenLoaded('roomBooms')),
            'rewards' => RoomBoomRewardResource::collection($this->whenLoaded('roomBoomRewards')),
        ];
    }
}
