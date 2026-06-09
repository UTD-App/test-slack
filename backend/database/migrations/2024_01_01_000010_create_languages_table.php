<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('languages', function (Blueprint $table) {
            $table->id();
            $table->string('code', 10)->unique();  // en, ar, fr, tr ...
            $table->string('name');                 // English, العربية, Français ...
            $table->string('native_name');          // same but in the language itself
            $table->boolean('is_rtl')->default(false);
            $table->boolean('is_active')->default(true);
            $table->boolean('is_default')->default(false);
            $table->timestamps();
        });

        Schema::create('translation_keys', function (Blueprint $table) {
            $table->id();
            $table->string('key')->unique();       // e.g. auth.login, home.welcome
            $table->string('group')->default('app'); // group for organizing
            $table->timestamps();
        });

        Schema::create('translations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('language_id')->constrained()->cascadeOnDelete();
            $table->foreignId('translation_key_id')->constrained()->cascadeOnDelete();
            $table->text('value')->nullable();
            $table->timestamps();
            $table->unique(['language_id', 'translation_key_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('translations');
        Schema::dropIfExists('translation_keys');
        Schema::dropIfExists('languages');
    }
};
