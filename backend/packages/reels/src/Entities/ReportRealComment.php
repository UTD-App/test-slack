<?php

namespace Utd\Reels\Entities;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;

class ReportRealComment extends Model
{
    protected $table = 'report_real_comments';

    protected $fillable = ['comment_id', 'real_id', 'Reporter_id', 'Reported_id', 'description', 'type'];

    protected $guarded = [];

    public function comment()
    {
        return $this->belongsTo(RealUserComment::class, 'comment_id');
    }

    public function reel()
    {
        return $this->belongsTo(Real::class, 'real_id');
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
