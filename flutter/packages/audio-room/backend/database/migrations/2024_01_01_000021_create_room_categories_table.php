<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('room_categories', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('parent_id')->nullable();
            $table->string('name');
            $table->string('name_en')->nullable();
            $table->string('img')->nullable();
            $table->boolean('enable')->default(true);
            $table->integer('sort')->default(0);
            $table->timestamps();

            $table->index('parent_id');
            $table->foreign('parent_id')->references('id')->on('room_categories')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('room_categories');
    }
};
