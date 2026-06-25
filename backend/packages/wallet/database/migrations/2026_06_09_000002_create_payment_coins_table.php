<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Coin payment package groups (from Eagle `payment_coins`). A `type`
     * (e.g. card, wallet, gateway) within a `package_type` (user | shipping_agency)
     * groups the purchasable `coins` packages shown in the recharge screen.
     */
    public function up(): void
    {
        Schema::create('payment_coins', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->string('photo')->nullable();
            $table->boolean('status')->default(true);
            $table->string('type')->nullable();
            $table->string('package_type')->default('user'); // user | shipping_agency
            $table->text('description')->nullable();
            $table->timestamps();

            $table->unique(['type', 'package_type']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payment_coins');
    }
};
