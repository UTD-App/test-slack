<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Per-user notification preferences. A row means the user has overridden the
 * default for a (category[, channel]) pair. Absence = enabled (default-on).
 * `channel` NULL = applies to the whole category across every channel.
 */
return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('notification_preferences')) {
            return;
        }

        Schema::create('notification_preferences', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('user_id');
            $table->string('category');                 // social / finance / system …
            $table->string('channel')->nullable();      // null = all channels
            $table->boolean('enabled')->default(true);
            $table->timestamps();

            $table->unique(['user_id', 'category', 'channel'], 'notif_pref_unique');
            $table->index('user_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('notification_preferences');
    }
};
