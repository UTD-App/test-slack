<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Pk extends Model
{
    protected $guarded = [];

    public function getT1PerAttribute(): string
    {
        $total = $this->t1_score + $this->t2_score;

        return number_format($total > 0 ? $this->t1_score / $total : 0.5, 2);
    }

    public function getT2PerAttribute(): string
    {
        $total = $this->t1_score + $this->t2_score;

        return number_format($total > 0 ? $this->t2_score / $total : 0.5, 2);
    }

    public function team1Boss(): BelongsTo
    {
        return $this->belongsTo(User::class, 'team_1_boss')->with('profile');
    }

    public function team2Boss(): BelongsTo
    {
        return $this->belongsTo(User::class, 'team_2_boss')->with('profile');
    }

    public function room(): BelongsTo
    {
        return $this->belongsTo(Room::class, 'room_id');
    }

    protected static function booted(): void
    {
        static::creating(function (Pk $pk) {
            if ($pk->mics) {
                $mics = explode(',', $pk->mics);
                if (count($mics) >= 8) {
                    $pk->team_1 = implode(',', [$mics[0], $mics[1], $mics[4], $mics[5]]);
                    $pk->team_2 = implode(',', [$mics[2], $mics[3], $mics[6], $mics[7]]);
                }
            }
        });

        static::updating(function (Pk $pk) {
            if ($pk->isDirty('mics') && $pk->mics) {
                $mics = explode(',', $pk->mics);
                if (count($mics) >= 8) {
                    $pk->team_1 = implode(',', [$mics[0], $mics[1], $mics[4], $mics[5]]);
                    $pk->team_2 = implode(',', [$mics[2], $mics[3], $mics[6], $mics[7]]);
                }
            }
        });
    }
}
