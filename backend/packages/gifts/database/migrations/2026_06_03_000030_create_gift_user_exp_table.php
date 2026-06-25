<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Accumulated gift EXP per user — the source of truth for sender/receiver levels.
 * A user EARNS exp on every gift: sender exp ← coins spent × exp_per_coin,
 * receiver exp ← diamonds earned × exp_per_diamond (rates set in admin, see
 * gift_settings). The level is then derived on read as the highest gift_levels
 * row of that kind whose threshold is <= the stored exp. Exp is stored (not a
 * live SUM) so changing a rate only affects future gifts — never retroactively
 * demotes anyone. One row per user.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('gift_user_exp', function (Blueprint $table) {
            $table->unsignedBigInteger('user_id')->primary();
            $table->unsignedBigInteger('sender_exp')->default(0);   // from coins spent
            $table->unsignedBigInteger('receiver_exp')->default(0); // from diamonds earned
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('gift_user_exp');
    }
};
