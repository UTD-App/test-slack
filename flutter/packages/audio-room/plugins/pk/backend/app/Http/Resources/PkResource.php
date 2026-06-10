<?php

namespace App\Http\Resources;

use App\Models\User;
use Illuminate\Http\Resources\Json\JsonResource;

class PkResource extends JsonResource
{
    public function toArray($request): array
    {
        $team1 = User::whereIn('id', explode(',', $this->team_1))
            ->select('id', 'name', 'uuid')->get();
        $team2 = User::whereIn('id', explode(',', $this->team_2))
            ->select('id', 'name', 'uuid')->get();

        return [
            'id' => $this->id,
            't1_score' => $this->t1_score,
            't2_score' => $this->t2_score,
            'winner' => $this->winner,
            'start_at' => $this->start_at,
            'end_at' => $this->end_at,
            'team_1' => $team1,
            'team_2' => $team2,
        ];
    }
}
