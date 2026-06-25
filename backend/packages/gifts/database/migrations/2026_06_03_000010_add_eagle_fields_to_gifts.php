<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Aligns the gift catalog with Eagle's gift fields that were missing here:
 *  - show_img2          : a second animation asset (Eagle ships two).
 *  - international_gift  : flag exposed to the app (global vs local gift).
 *  - use_count          : how many times the gift was sent (popularity ordering).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('gifts', function (Blueprint $table) {
            $table->string('show_img2')->nullable()->after('show_img');
            $table->boolean('international_gift')->default(false)->after('music_gift');
            $table->unsignedBigInteger('use_count')->default(0)->after('enable');
        });
    }

    public function down(): void
    {
        Schema::table('gifts', function (Blueprint $table) {
            $table->dropColumn(['show_img2', 'international_gift', 'use_count']);
        });
    }
};
