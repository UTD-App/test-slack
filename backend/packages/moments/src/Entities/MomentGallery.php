<?php

namespace Utd\Moment\Entities;

use Illuminate\Database\Eloquent\Model;

/**
 * Moment image (one row per uploaded image of a moment).
 * Moment-specific, so it ships inside the package (was App\Models\MomentGallery in Eagle).
 */
class MomentGallery extends Model
{
    protected $table = 'moment_galleries';

    protected $fillable = ['moment_id', 'image'];

    protected $guarded = [];

    public function moment()
    {
        return $this->belongsTo(Moment::class);
    }
}
