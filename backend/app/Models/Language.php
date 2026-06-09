<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Language extends Model
{
    protected $guarded = [];

    protected $casts = [
        'is_rtl'     => 'boolean',
        'is_active'  => 'boolean',
        'is_default' => 'boolean',
    ];

    public function translations()
    {
        return $this->hasMany(Translation::class);
    }
}
