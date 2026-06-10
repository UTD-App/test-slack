<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class ThemeBoomLevelResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'level' => $this->level,
            'background' => [
                'type' => $this->image_type_background ?? '',
                'url' => $this->background_image ?? '',
            ],
            'boom' => [
                'type' => $this->image_type_boom ?? '',
                'url' => $this->boom_image ?? '',
            ],
        ];
    }
}
