<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Coin purchase log from payment gateways (from Eagle `coin_logs`, ALTERs merged).
     * One row per recharge attempt (Stripe / Google Pay / Huawei / Paytabs / web).
     * Lifecycle: status 0 = pending, 1 = done. When marked done it credits the
     * wallet (a `wallet_transactions` row is written and balance increased).
     */
    public function up(): void
    {
        Schema::create('coin_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('coin_id')->nullable()->constrained('coins')->nullOnDelete();
            $table->double('paid_usd')->default(0);
            $table->unsignedBigInteger('obtained_coins')->default(0);
            $table->string('method')->nullable();    // stripe | google_pay | huawei_pay | paytabs | web ...
            $table->unsignedBigInteger('donor_id')->nullable();
            $table->string('donor_type')->nullable(); // user | shipping_agency
            $table->string('user_type')->nullable();
            $table->unsignedTinyInteger('status')->default(0); // 0 = pending, 1 = done
            $table->string('trx')->nullable();        // gateway transaction id
            $table->string('pid')->nullable();        // parent / order id
            $table->timestamps();

            $table->index(['user_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('coin_logs');
    }
};
