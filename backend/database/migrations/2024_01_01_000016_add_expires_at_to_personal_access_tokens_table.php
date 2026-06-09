<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Older installs created `personal_access_tokens` without `expires_at`
     * (pre-Sanctum-2.x layout). The installed Sanctum writes `expires_at`
     * on every token, so registration/login fail with "Unknown column
     * 'expires_at'". Add it here for databases that already have the table.
     */
    public function up(): void
    {
        if (Schema::hasTable('personal_access_tokens')
            && ! Schema::hasColumn('personal_access_tokens', 'expires_at')) {
            Schema::table('personal_access_tokens', function (Blueprint $table) {
                $table->timestamp('expires_at')->nullable()->after('last_used_at');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('personal_access_tokens', 'expires_at')) {
            Schema::table('personal_access_tokens', function (Blueprint $table) {
                $table->dropColumn('expires_at');
            });
        }
    }
};
