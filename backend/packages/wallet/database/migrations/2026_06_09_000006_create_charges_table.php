<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Manual charge (base from oldbranch Utd\Wallet `charges`: polymorphic
     * charger/target + usd + link to the ledger row), enriched with Eagle's
     * `is_used_transferred`, `reason_en/ar` and `invoice` (folds charge_invoices).
     *
     * `charger` = who charged (admin / agency / area-manager / bd); null = system/payment.
     * `target`  = who received (user / agency). Balance itself moves via the wallet;
     * this row is the charge-specific history linked to its ledger entry.
     */
    public function up(): void
    {
        Schema::create('charges', function (Blueprint $table) {
            $table->id();
            $table->nullableMorphs('charger');
            $table->morphs('target');
            $table->string('currency')->default('coins');
            $table->decimal('amount', 20, 2);          // signed: +charge / -deduct
            $table->decimal('balance_before', 20, 2)->default(0);
            $table->decimal('balance_after', 20, 2)->default(0);
            $table->decimal('usd', 18, 3)->nullable(); // filled when a conversion rate applies
            $table->boolean('is_used_transferred')->default(false);
            $table->string('reason')->nullable();
            $table->longText('reason_en')->nullable();
            $table->longText('reason_ar')->nullable();
            $table->string('invoice')->nullable();     // invoice file (folds Eagle charge_invoices)
            $table->json('meta')->nullable();
            $table->foreignId('wallet_transaction_id')->nullable()
                ->constrained('wallet_transactions')->nullOnDelete();
            $table->timestamps();

            $table->index('created_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('charges');
    }
};
