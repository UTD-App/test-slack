<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Optional idempotency key for a ledger movement. Callers that retry a money
     * operation (payment webhook, gift, exchange) pass meta['idempotency_key'];
     * DatabaseWallet then dedupes on it so a retry never double-credits/debits.
     * Nullable + unique → existing callers (no key) are unaffected (many NULLs ok).
     */
    public function up(): void
    {
        Schema::table('wallet_transactions', function (Blueprint $table) {
            if (! Schema::hasColumn('wallet_transactions', 'idempotency_key')) {
                $table->string('idempotency_key')->nullable()->after('reference_id');
                $table->unique('idempotency_key');
            }
        });
    }

    public function down(): void
    {
        Schema::table('wallet_transactions', function (Blueprint $table) {
            if (Schema::hasColumn('wallet_transactions', 'idempotency_key')) {
                $table->dropUnique(['idempotency_key']);
                $table->dropColumn('idempotency_key');
            }
        });
    }
};
