<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class BoomPercentageResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'percentage' => $this->percentage,
            'image' => $this->image ?? '',
            'image_type' => $this->image_type ?? '',
        ];
    }
}
