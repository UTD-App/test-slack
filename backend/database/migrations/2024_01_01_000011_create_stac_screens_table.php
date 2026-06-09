<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('stac_screens', function (Blueprint $table) {
            $table->id();
            $table->string('name')->unique();        // screen identifier e.g. "home", "gift_popup"
            $table->string('package')->default('base'); // which package owns this screen
            $table->string('version')->default('1');   // bumped when screen JSON changes
            $table->json('content');                   // the Stac JSON
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('stac_screens');
    }
};
