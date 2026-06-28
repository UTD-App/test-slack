<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Idempotent: some assemblies already carry this column from a legacy
        // schema, so only add it when missing.
        if (Schema::hasColumn('real_user_comments', 'parent_id')) {
            return;
        }

        Schema::table('real_user_comments', function (Blueprint $table) {
            // One-level replies: a comment may reply to another comment on the
            // same reel. Null = top-level comment.
            $table->foreignId('parent_id')->nullable()->after('real_id')
                ->constrained('real_user_comments')->nullOnDelete();
        });
    }

    public function down(): void
    {
        if (! Schema::hasColumn('real_user_comments', 'parent_id')) {
            return;
        }

        Schema::table('real_user_comments', function (Blueprint $table) {
            $table->dropColumn('parent_id');
        });
    }
};
