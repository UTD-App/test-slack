<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('codes')) {
            return;
        }

        // OTP codes for the WhatsApp-based password recovery flow.
        // Mirrors Eagle's `codes` table: one row per generated code, looked up by
        // phone + code with a created_at validity window (see WhatsappOtp service).
        Schema::create('codes', function (Blueprint $table) {
            $table->id();
            $table->string('phone')->index();
            $table->string('code');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('codes');
    }
};
