<?php

namespace App\Http\Resources;

use App\Models\Gift;
use App\Models\Ware;
use Illuminate\Http\Resources\Json\JsonResource;

class RoomBoomRewardResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->id,
            'priority' => $this->priority,
            'type' => $this->target_type,
            'image' => $this->getImageUrl(),
            'price' => $this->getPrice(),
            'gift_image_type' => $this->getGiftImageType() ?? '',
            'title' => $this->getTitle() . ($this->expire_days ? ' - ' . $this->expire_days . ' days' : ''),
            'count' => $this->quantity,
        ];
    }

    protected function getGiftImageType(): ?string
    {
        if ($this->target_type === 'gift') {
            return Gift::find($this->target)?->image_type;
        }
        return null;
    }

    protected function getImageUrl(): string
    {
        $path = match ($this->target_type) {
            'ware' => Ware::find($this->target)?->show_img ?? Ware::find($this->target)?->img2 ?? '',
            'gift' => Gift::find($this->target)?->img ?? '',
            'achievement' => $this->target,
            'coin' => 'coin.png',
            default => '',
        };

        return getImagePath($path);
    }

    protected function getTitle(): string
    {
        return match ($this->target_type) {
            'ware' => Ware::find($this->target)?->name ?? '',
            'gift' => Gift::find($this->target)?->name ?? '',
            'achievement' => 'Achievement',
            'coin' => 'Coin',
            default => '',
        };
    }

    protected function getPrice(): int
    {
        return match ($this->target_type) {
            'ware' => Ware::find($this->target)?->price ?? 0,
            'gift' => Gift::find($this->target)?->price ?? 0,
            'coin' => (int) $this->target,
            default => 0,
        };
    }
}
