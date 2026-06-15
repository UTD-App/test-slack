<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Static content pages (privacy policy, about us, terms, …) — admin-editable,
 * served to the app by key. Title/body are localized JSON ({en, ar}).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('pages', function (Blueprint $table) {
            $table->id();
            $table->string('key')->unique(); // privacy-policy, about-us, terms, ...
            $table->json('title');           // {en, ar}
            $table->json('body');            // {en, ar}
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pages');
    }
};
