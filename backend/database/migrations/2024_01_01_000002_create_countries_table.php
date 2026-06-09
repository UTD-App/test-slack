<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('countries', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('e_name')->nullable();
            $table->string('flag')->nullable();
            $table->string('language')->default('en');
            $table->string('phone_code')->nullable();
            $table->string('iso', 3)->nullable();
            $table->string('iso_numeric', 5)->nullable();
            $table->string('currency_numeric', 5)->nullable();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('countries');
    }
};
