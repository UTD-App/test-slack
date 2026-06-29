<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // De-dupe any existing rows (keep the earliest) before enforcing one
        // reaction per user per reel. DB-agnostic so it also runs under sqlite.
        $dupes = DB::table('real_user_likes')
            ->select('real_id', 'user_id', DB::raw('MIN(id) as keep_id'))
            ->groupBy('real_id', 'user_id')
            ->havingRaw('COUNT(*) > 1')
            ->get();

        foreach ($dupes as $dupe) {
            DB::table('real_user_likes')
                ->where('real_id', $dupe->real_id)
                ->where('user_id', $dupe->user_id)
                ->where('id', '!=', $dupe->keep_id)
                ->delete();
        }

        Schema::table('real_user_likes', function (Blueprint $table) {
            $table->unique(['real_id', 'user_id']);
        });
    }

    public function down(): void
    {
        Schema::table('real_user_likes', function (Blueprint $table) {
            $table->dropUnique(['real_id', 'user_id']);
        });
    }
};
