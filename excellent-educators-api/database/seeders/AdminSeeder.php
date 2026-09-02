<?php

namespace Database\Seeders;

use App\Enums\RoleName;
use App\Enums\UserStatus;
use App\Models\User;
use Illuminate\Database\Seeder;

class AdminSeeder extends Seeder
{
    public function run(): void
    {
        $admins = [
            [
                'name' => 'Admin 1',
                'email' => 'admin1@excellenteducators.test',
                'password' => env('SEED_ADMIN1_PASSWORD', 'ChangeMeAdmin1!'),
                'role' => RoleName::SuperAdmin,
            ],
            [
                'name' => 'Admin 2',
                'email' => 'admin2@excellenteducators.test',
                'password' => env('SEED_ADMIN2_PASSWORD', 'ChangeMeAdmin2!'),
                'role' => RoleName::OperationalAdmin,
            ],
            [
                'name' => 'Admin 3',
                'email' => 'admin3@excellenteducators.test',
                'password' => env('SEED_ADMIN3_PASSWORD', 'ChangeMeAdmin3!'),
                'role' => RoleName::OperationalAdmin,
            ],
        ];

        foreach ($admins as $admin) {
            $user = User::query()->updateOrCreate(
                ['email' => $admin['email']],
                [
                    'name' => $admin['name'],
                    'password' => $admin['password'],
                    'status' => UserStatus::Active,
                    'email_verified_at' => now(),
                ],
            );

            $user->syncRoles([$admin['role']->value]);
        }
    }
}
