<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('rooms', function (Blueprint $table) {
            if (!Schema::hasColumn('rooms', 'is_show_pk')) {
                $table->boolean('is_show_pk')->default(false);
            }
            if (!Schema::hasColumn('rooms', 'is_pk_custom')) {
                $table->boolean('is_pk_custom')->default(false);
            }
        });
    }

    public function down(): void
    {
        Schema::table('rooms', function (Blueprint $table) {
            $table->dropColumn(['is_show_pk', 'is_pk_custom']);
        });
    }
};
