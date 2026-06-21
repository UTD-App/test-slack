<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('rooms', function (Blueprint $table) {
            $table->string('empty_seat_icon')->nullable()->after('max_admin');
            $table->string('locked_seat_icon')->nullable()->after('empty_seat_icon');
        });
    }

    public function down(): void
    {
        Schema::table('rooms', function (Blueprint $table) {
            $table->dropColumn(['empty_seat_icon', 'locked_seat_icon']);
        });
    }
};
