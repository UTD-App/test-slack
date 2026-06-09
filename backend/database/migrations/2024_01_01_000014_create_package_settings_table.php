<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('package_settings', function (Blueprint $table) {
            $table->id();
            $table->string('package')->default('base'); // owning package slug
            $table->string('key')->unique();            // dot-namespaced, mirrors Flutter UserSettingDefinition.key
            $table->string('type')->default('bool');    // bool|string|int|json
            $table->json('default_value')->nullable();
            $table->string('label_key')->nullable();    // translation key
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('package_settings');
    }
};
