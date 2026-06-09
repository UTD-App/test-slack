<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Config extends Model
{
    protected $table = 'configs';

    protected $guarded = [];

    protected $casts = [
        'is_hidden' => 'boolean',
    ];
}
