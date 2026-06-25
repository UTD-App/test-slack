<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('gift_categories', function (Blueprint $table) {
            $table->id();
            $table->json('title');                 // multi-language: {"en":"Popular","ar":"الأكثر"}
            $table->string('type')->default('normal'); // normal | lucky | cp
            $table->bigInteger('sort')->default(0);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('gift_categories');
    }
};
