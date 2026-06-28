<?php

namespace Utd\Reels\Entities;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;

class ReportReals extends Model
{
    protected $table = 'report_reals';

    protected $fillable = ['real_id', 'Reporter_id', 'Reported_id', 'description', 'type'];

    protected $guarded = [];

    public function reel()
    {
        return $this->hasOne(Real::class, 'id', 'real_id');
    }

    public function reporter()
    {
        return $this->belongsTo(User::class, 'Reporter_id');
    }

    public function reportedUser()
    {
        return $this->belongsTo(User::class, 'Reported_id');
    }
}
