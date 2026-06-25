<?php

namespace Utd\Moment\Entities;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;

class ReportMomentComment extends Model
{
    protected $table = 'report_moment_comments';

    protected $fillable = ['comment_id', 'moment_id', 'Reporter_id', 'Reported_id', 'description', 'type'];

    protected $guarded = [];

    public function comment()
    {
        return $this->belongsTo(MomentCommint::class, 'comment_id');
    }

    public function moment()
    {
        return $this->belongsTo(Moment::class, 'moment_id');
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
