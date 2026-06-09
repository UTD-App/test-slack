<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('packages', function (Blueprint $table) {
            $table->id();
            $table->string('slug')->unique();          // 'audio-room' — matches Module dir + translation group + roles.package
            $table->string('name');                    // display name
            $table->string('version')->default('1.0.0');
            $table->boolean('enabled')->default(true);
            $table->boolean('is_core')->default(false); // core packages cannot be disabled from the panel
            $table->json('dependencies')->nullable();   // ["slug-a","slug-b"]
            $table->unsignedInteger('order')->default(0);
            $table->json('meta')->nullable();           // capability manifest snapshot
            $table->timestamp('installed_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('packages');
    }
};
