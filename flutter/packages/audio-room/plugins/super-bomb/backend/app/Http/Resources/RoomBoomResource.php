<?php

namespace App\Http\Resources;

use Carbon\Carbon;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\DB;
use App\Http\Resources\Api\V1\TopUsersRankResource;
use App\Models\RoomBoomTopContributor;

class RoomBoomResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->id,
            'started_at' => $this->started_at,
            'ended_at' => $this->ended_at,
            'total_gifts_value' => $this->total_gifts_value,
            'level' => $this->roomBoomLevel?->level,
            'top_contributors' => $this->ended_at
                ? TopUsersRankResource::collection($this->getTopContributors())
                : [],
        ];
    }

    protected function getTopContributors(): Collection|array
    {
        return RoomBoomTopContributor::query()
            ->select(
                'user_id',
                DB::raw('SUM(price) as total_gift'),
                DB::raw('MIN(created_at) as first_contribution')
            )
            ->where('room_boom_level_id', $this->room_boom_level_id)
            ->where('total_room_gift_id', $this->total_room_gift_id)
            ->whereDate('created_at', '>=', Carbon::today())
            ->groupBy('user_id')
            ->orderByDesc('total_gift')
            ->orderBy('first_contribution')
            ->limit(10)
            ->get();
    }
}
