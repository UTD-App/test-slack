<?php

namespace Utd\Moment\Entities;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;

class ReportMoment extends Model
{
    protected $table = 'report_moments';

    protected $fillable = ['moment_id', 'Reporter_id', 'Reported_id', 'description', 'type'];

    protected $guarded = [];

    public function moment()
    {
        return $this->belongsTo(Moment::class);
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
