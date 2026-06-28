<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Idempotent: skip if a legacy schema already added this column.
        if (Schema::hasColumn('real_user_likes', 'reaction_type')) {
            return;
        }

        Schema::table('real_user_likes', function (Blueprint $table) {
            // Facebook-style reaction: like/love/haha/wow/sad/angry. Existing
            // rows default to 'like'. One reaction per user per reel.
            $table->string('reaction_type')->default('like')->after('user_id');
        });
    }

    public function down(): void
    {
        if (! Schema::hasColumn('real_user_likes', 'reaction_type')) {
            return;
        }

        Schema::table('real_user_likes', function (Blueprint $table) {
            $table->dropColumn('reaction_type');
        });
    }
};
