<?php

namespace Database\Seeders;

use App\Models\AdminRole;
use App\Models\AdminUser;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class AdminUserSeeder extends Seeder
{
    public function run(): void
    {
        // Create default super admin if none exists
        $admin = AdminUser::firstOrCreate(
            ['email' => 'admin@admin.com'],
            [
                'name'      => 'Admin',
                'password'  => Hash::make('Admin@' . date('Y')),
                'is_active' => true,
            ]
        );

        // Assign super_admin role automatically
        $superAdminRole = AdminRole::firstOrCreate(
            ['name' => 'super_admin'],
            ['label' => 'Super Admin']
        );

        $admin->roles()->syncWithoutDetaching([$superAdminRole->id]);

        $this->command->info("Admin created: {$admin->email} / Admin@" . date('Y'));
        $this->command->info('Role: super_admin assigned');
    }
}
