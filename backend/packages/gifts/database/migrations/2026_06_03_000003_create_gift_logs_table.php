<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Every gift sent: who → whom, what, how much spent (coins) and earned
        // (diamonds), and the context it was sent in (moment/reel/room…). Linked to
        // the wallet_transactions ledger rows for the debit and the credit.
        Schema::create('gift_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('gift_id')->nullable()->constrained('gifts')->nullOnDelete();
            $table->string('gift_name')->nullable();           // snapshot
            $table->foreignId('sender_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('receiver_id')->constrained('users')->cascadeOnDelete();
            $table->unsignedInteger('gift_num')->default(1);
            $table->decimal('unit_price', 20, 2)->default(0);
            $table->decimal('total_price', 20, 2)->default(0); // coins spent by sender
            $table->string('spend_currency')->default('coins');
            $table->string('earn_currency')->default('diamonds');
            $table->decimal('receiver_earned', 20, 2)->default(0); // diamonds credited

            // Context the gift was sent in (decoupled — plain alias, no morph class).
            $table->string('context_type')->nullable();        // e.g. 'moment'
            $table->unsignedBigInteger('context_id')->nullable();

            $table->unsignedBigInteger('wallet_debit_tx_id')->nullable();
            $table->unsignedBigInteger('wallet_credit_tx_id')->nullable();

            // Batch grouping for a multi-receiver send (Eagle's room_boom_uuid):
            // one sender action → many gift_logs sharing this id.
            $table->uuid('batch_id')->nullable();
            $table->string('source')->default('coins'); // coins | bag
            $table->boolean('is_lucky')->default(false);

            $table->json('meta')->nullable();
            $table->timestamps();

            $table->index('sender_id');
            $table->index('receiver_id');
            $table->index(['context_type', 'context_id']);
            $table->index('batch_id');
            $table->index('created_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('gift_logs');
    }
};
