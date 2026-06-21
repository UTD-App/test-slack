<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call([
            LanguageSeeder::class,
            AdminUserSeeder::class,
            AdminPermissionSeeder::class,
            PagesSeeder::class,
            EmailTemplateSeeder::class,
        ]);
    }
}
