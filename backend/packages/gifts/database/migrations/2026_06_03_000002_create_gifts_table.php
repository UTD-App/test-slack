<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // The gift catalog. `type`: 1=normal … 6=lucky (lucky needs the lucky-gift plugin).
        Schema::create('gifts', function (Blueprint $table) {
            $table->id();
            $table->string('name')->nullable();
            $table->string('e_name')->nullable();
            $table->unsignedTinyInteger('type')->default(1);
            $table->foreignId('gift_category_id')->nullable()->constrained('gift_categories')->nullOnDelete();
            $table->unsignedTinyInteger('vip_level')->default(0);
            $table->unsignedBigInteger('price')->default(0);   // cost in coins
            $table->string('img')->nullable();                  // thumbnail URL/path
            $table->string('show_img')->nullable();             // animation URL/path (mp4/svga/lottie)
            $table->string('image_type')->nullable();           // svga | mp4 | lottie
            $table->boolean('music_gift')->default(false);
            $table->boolean('is_play')->default(false);         // has broadcast animation
            $table->bigInteger('sort')->default(0);
            $table->boolean('enable')->default(true);
            $table->timestamps();

            $table->index(['enable', 'gift_category_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('gifts');
    }
};
