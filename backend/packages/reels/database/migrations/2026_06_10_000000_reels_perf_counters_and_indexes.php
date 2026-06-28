<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Performance hardening for the reels feed at high concurrency.
 *
 * - Adds a denormalized `view_num` counter (like_num/comment_num already exist).
 *   Reads now come from these columns instead of per-row withCount() subqueries,
 *   and view writes become an atomic increment instead of a row-per-play insert.
 * - Adds composite (real_id, user_id) indexes that the per-user likeExists EXISTS
 *   subquery and like/comment dedup lookups hit on every feed request.
 * - Backfills the counters once from the existing pivot rows.
 */
return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasColumn('reals', 'view_num')) {
            Schema::table('reals', function (Blueprint $table) {
                $table->integer('view_num')->default(0);
            });
        }

        // The single FK index on real_id stays (the FK requires it); the composite
        // makes (real_id, user_id) lookups index-only.
        Schema::table('real_user_likes', function (Blueprint $table) {
            $table->index(['real_id', 'user_id'], 'rul_real_user_idx');
        });
        Schema::table('real_user_comments', function (Blueprint $table) {
            $table->index(['real_id', 'user_id'], 'ruc_real_user_idx');
        });

        // One-time backfill from the pivot tables (correlated UPDATEs run on both
        // MySQL and the sqlite test DB).
        DB::statement('UPDATE reals SET like_num = (SELECT COUNT(*) FROM real_user_likes WHERE real_user_likes.real_id = reals.id)');
        DB::statement('UPDATE reals SET comment_num = (SELECT COUNT(*) FROM real_user_comments WHERE real_user_comments.real_id = reals.id)');
        DB::statement('UPDATE reals SET view_num = (SELECT COUNT(*) FROM real_user_views WHERE real_user_views.real_id = reals.id)');
    }

    public function down(): void
    {
        Schema::table('real_user_likes', function (Blueprint $table) {
            $table->dropIndex('rul_real_user_idx');
        });
        Schema::table('real_user_comments', function (Blueprint $table) {
            $table->dropIndex('ruc_real_user_idx');
        });
        if (Schema::hasColumn('reals', 'view_num')) {
            Schema::table('reals', function (Blueprint $table) {
                $table->dropColumn('view_num');
            });
        }
    }
};
