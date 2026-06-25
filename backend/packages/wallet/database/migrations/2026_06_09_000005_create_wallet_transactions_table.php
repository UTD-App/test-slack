<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Unified coin ledger (base from oldbranch Utd\Wallet `wallet_transactions`,
     * enriched with `sub_type` + `item_name` from Eagle `user_coin_logs`).
     * One row per coin movement. `type` uses CoinTransactionType (gift, payment,
     * admin_charge, exchange, game, ...). `reference` polymorphically links the
     * source row (a Charge, a CoinLog, a Gift, ...).
     */
    public function up(): void
    {
        Schema::create('wallet_transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('wallet_id')->constrained('user_wallets')->onDelete('cascade');
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            $table->string('currency')->index();
            $table->string('type')->index();        // CoinTransactionType
            $table->string('sub_type')->nullable();  // grouping (rooms, gifts, charges, ...) from Eagle
            $table->decimal('amount', 20, 2);        // signed: +credit / -debit
            $table->decimal('balance_before', 20, 2)->default(0);
            $table->decimal('balance_after', 20, 2)->default(0);
            $table->string('item_name')->nullable(); // human description
            $table->nullableMorphs('reference');     // source row (optional)
            $table->json('meta')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('wallet_transactions');
    }
};
