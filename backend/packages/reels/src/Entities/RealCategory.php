<?php

namespace Utd\Reels\Entities;

use Illuminate\Database\Eloquent\Model;

class RealCategory extends Model
{
    protected $table = 'reals_categories';

    protected $fillable = ['real_id', 'category_id'];

    protected $guarded = [];

    public function real()
    {
        return $this->belongsTo(Real::class, 'real_id', 'id');
    }
}
