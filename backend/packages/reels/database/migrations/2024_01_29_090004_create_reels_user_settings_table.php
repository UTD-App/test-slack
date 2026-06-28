<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Per-user reel feed state (random-order seeds + last-seen markers).
     *
     * NOTE: Eagle's version also dropped a `users.real_type` column here. The Base
     * never adds that column (see NOTES_GAPS — `real_type` stays a transient
     * in-memory attribute), so this migration only creates the settings table.
     */
    public function up(): void
    {
        Schema::create('reels_user_settings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            $table->string('all_unique_value')->nullable();
            $table->string('following_unique_value')->nullable();
            $table->integer('last_all_reel_id')->nullable();
            $table->integer('last_following_reel_id')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('reels_user_settings');
    }
};
