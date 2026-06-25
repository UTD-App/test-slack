<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Small key/value store for admin-tunable Gifts settings (the package owns its
 * own knobs instead of leaning on the Base config table). Currently holds the
 * EXP conversion rates edited on the GiftExpSettings Filament page:
 *   exp_per_coin     — EXP a sender gains per 1 coin spent
 *   exp_per_diamond  — EXP a receiver gains per 1 diamond earned
 * Missing keys fall back to config('gifts.*') defaults via Support\GiftSettings.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('gift_settings', function (Blueprint $table) {
            $table->id();
            $table->string('key')->unique();
            $table->text('value')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('gift_settings');
    }
};
