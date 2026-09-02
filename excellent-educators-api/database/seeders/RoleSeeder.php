<?php

namespace Database\Seeders;

use App\Enums\PermissionName;
use App\Enums\RoleName;
use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;
use Spatie\Permission\PermissionRegistrar;

class RoleSeeder extends Seeder
{
    public function run(): void
    {
        app(PermissionRegistrar::class)->forgetCachedPermissions();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }

        foreach (RoleName::cases() as $role) {
            Role::findOrCreate($role->value, 'web');
        }

        $adminPermissions = [
            PermissionName::AssessmentsManage->value,
            PermissionName::AssessmentsView->value,
            PermissionName::FeedbackManage->value,
            PermissionName::FeedbackView->value,
        ];

        Role::findByName(RoleName::SuperAdmin->value, 'web')->syncPermissions($adminPermissions);
        Role::findByName(RoleName::OperationalAdmin->value, 'web')->syncPermissions($adminPermissions);
    }
}
