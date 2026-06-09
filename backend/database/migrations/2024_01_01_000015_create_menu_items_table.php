<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('menu_items', function (Blueprint $table) {
            $table->id();
            $table->string('slug')->unique();            // stable id == Flutter UiContribution.contributionId
            $table->string('package')->default('base');  // owning package slug
            $table->string('label_key');                 // translation key, e.g. 'audio_room.menu_lobby'
            $table->string('icon')->nullable();          // icon token resolved client-side
            $table->string('active_icon')->nullable();
            $table->string('route')->nullable();         // optional deep-link/route path
            $table->string('slot');                      // matches Flutter UiSlot.name (bottomNav/drawer/home/...)
            $table->foreignId('parent_id')->nullable()->constrained('menu_items')->nullOnDelete();
            $table->unsignedInteger('order')->default(0);
            $table->boolean('is_visible')->default(true);
            $table->json('roles')->nullable();           // null/[] = everyone; else role keys gating visibility
            $table->string('target')->default('app');    // app | dashboard | both
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('menu_items');
    }
};
