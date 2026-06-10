<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('boom_percentages', function (Blueprint $table) {
            $table->id();
            $table->integer('percentage');
            $table->string('image')->nullable();
            $table->string('image_type')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('boom_percentages');
    }
};
