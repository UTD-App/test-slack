<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

// Recovery moved to EMAIL OTP. The `codes` table now keys codes by email (phone
// kept nullable so the dormant WhatsApp path still compiles). `codes` only holds
// short-lived OTPs, so a drop+recreate is safe and portable (no ->change()).
return new class extends Migration
{
    public function up(): void
    {
        Schema::dropIfExists('codes');
        Schema::create('codes', function (Blueprint $table) {
            $table->id();
            $table->string('email')->nullable()->index();
            $table->string('phone')->nullable()->index();
            $table->string('code');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('codes');
        Schema::create('codes', function (Blueprint $table) {
            $table->id();
            $table->string('phone')->index();
            $table->string('code');
            $table->timestamps();
        });
    }
};
