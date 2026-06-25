<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Purchasable coin packages (from Eagle `coins`, all ALTERs merged).
     * Each package: pay `usd` -> get `coin` (+ `first_charge_coin` bonus on the
     * user's first purchase, + `extra_value` promo). Belongs to a payment group
     * via `payment_gateway_id` -> payment_coins.
     */
    public function up(): void
    {
        Schema::create('coins', function (Blueprint $table) {
            $table->id();
            $table->double('usd')->default(0);
            $table->unsignedBigInteger('coin')->default(0);
            $table->unsignedBigInteger('first_charge_coin')->default(0);
            $table->unsignedTinyInteger('status')->nullable();
            $table->string('discount_code')->nullable();
            $table->integer('discount_code_expire_in')->nullable(); // days
            $table->unsignedBigInteger('extra_value')->default(0);
            $table->integer('extra_value_end_in')->nullable();      // days
            $table->integer('sort')->default(0);
            $table->foreignId('payment_gateway_id')->nullable()
                ->constrained('payment_coins')->nullOnDelete();
            $table->timestamps();
            $table->softDeletes();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('coins');
    }
};
