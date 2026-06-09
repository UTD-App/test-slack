<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Country extends Model
{
    protected $fillable = [
        'name',
        'e_name',
        'flag',
        'language',
        'phone_code',
        'iso',
        'iso_numeric',
        'currency_numeric',
    ];

    public $timestamps = false;
}
