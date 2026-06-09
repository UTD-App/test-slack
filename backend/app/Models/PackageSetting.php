<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PackageSetting extends Model
{
    protected $guarded = [];

    protected $casts = [
        'default_value' => 'array',
    ];
}
