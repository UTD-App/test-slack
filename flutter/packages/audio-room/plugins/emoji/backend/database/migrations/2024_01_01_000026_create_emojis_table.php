<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('emojis', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('pid')->default(0);
            $table->string('name')->nullable();
            $table->string('name_en')->nullable();
            $table->string('emoji');
            $table->integer('t_length')->default(0);
            $table->tinyInteger('enable')->default(1);
            $table->bigInteger('sort')->default(0);
            $table->string('addtime')->nullable();
            $table->unsignedBigInteger('emoji_category_id')->nullable();
            $table->string('image_type')->nullable();
            $table->timestamps();

            $table->index(['enable', 'sort']);
            $table->index('emoji_category_id');
            $table->foreign('emoji_category_id')->references('id')->on('emoji_categories')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('emojis');
    }
};
