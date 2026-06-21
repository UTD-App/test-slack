<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasColumn('profiles', 'covers')) {
            return;
        }

        Schema::table('profiles', function (Blueprint $table) {
            // Up to N cover images shown as a swipeable banner on the profile.
            $table->json('covers')->nullable()->after('avatar');
        });
    }

    public function down(): void
    {
        if (! Schema::hasColumn('profiles', 'covers')) {
            return;
        }

        Schema::table('profiles', function (Blueprint $table) {
            $table->dropColumn('covers');
        });
    }
};
