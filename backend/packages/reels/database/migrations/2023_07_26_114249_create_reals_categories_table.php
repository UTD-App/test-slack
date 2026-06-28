<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('reals_categories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('real_id')->constrained('reals')->onDelete('cascade');
            // NOTE(gap): Eagle FK'd category_id → interests. The Base has no
            // `interests` catalog yet, so this is a plain id (no FK). See NOTES_GAPS.
            $table->unsignedBigInteger('category_id');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('reals_categories');
    }
};
