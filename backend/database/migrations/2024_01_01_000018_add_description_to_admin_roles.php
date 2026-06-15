<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasColumn('admin_roles', 'description')) {
            Schema::table('admin_roles', function (Blueprint $table) {
                $table->string('description', 255)->nullable()->after('label');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('admin_roles', 'description')) {
            Schema::table('admin_roles', function (Blueprint $table) {
                $table->dropColumn('description');
            });
        }
    }
};
