<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * User coin wallet (base design from oldbranch Utd\Wallet).
     * One row per (user, currency). Ships `coins`; `currency` is kept for
     * extensibility, but the dollar/earnings wallet lives in the target package.
     * available = balance - held (held = reserved for pending operations).
     */
    public function up(): void
    {
        Schema::create('user_wallets', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            $table->string('currency')->default('coins');
            $table->decimal('balance', 20, 2)->default(0);
            $table->decimal('held', 20, 2)->default(0);
            $table->timestamps();

            $table->unique(['user_id', 'currency']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_wallets');
    }
};
