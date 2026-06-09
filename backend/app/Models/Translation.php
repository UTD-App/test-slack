<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Translation extends Model
{
    protected $guarded = [];

    public function language()
    {
        return $this->belongsTo(Language::class);
    }

    public function key()
    {
        return $this->belongsTo(TranslationKey::class, 'translation_key_id');
    }
}
