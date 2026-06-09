<?php

namespace Utd\Moment\Entities;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;

class MomentCommint extends Model
{
    protected $table = 'moment_user_comments';

    protected $fillable = ['user_id', 'moment_id', 'comment'];

    protected $guarded = [];

    public function user()
    {
        return $this->hasOne(User::class, 'id', 'user_id');
    }

    public function moment()
    {
        return $this->belongsTo(Moment::class, 'moment_id', 'id');
    }
}
