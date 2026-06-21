<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * A one-time OTP code for the WhatsApp password-recovery flow.
 * Stored keyed by phone; validated against created_at (see WhatsappOtp).
 */
class Code extends Model
{
    protected $table = 'codes';

    protected $guarded = [];
}
