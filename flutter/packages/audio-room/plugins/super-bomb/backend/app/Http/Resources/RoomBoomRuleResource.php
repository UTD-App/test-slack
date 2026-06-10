<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class RoomBoomRuleResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->id,
            'rules_ar' => $this->rules_ar ?? '',
            'rules_en' => $this->rules_en ?? '',
            'content' => $this->content ?? '',
            'created_at' => $this->created_at?->format('Y-m-d H:i:s'),
        ];
    }
}
