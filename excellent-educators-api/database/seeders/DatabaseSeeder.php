<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        // System bootstrap — safe for production (roles, dimensions, site content).
        $this->call([
            RoleSeeder::class,
            DimensionSeeder::class,
            LoginPageContentSeeder::class,
            SitePageSeeder::class,
        ]);

        if (app()->environment('production')) {
            $this->command?->info(
                'Production: bootstrap seed complete. Create an admin with: php artisan app:create-admin',
            );

            return;
        }

        // Local/dev only: starter admin + Level 1/Batch 1 (no demo students/journeys).
        $this->call([
            AdminSeeder::class,
            LevelSeeder::class,
        ]);

        $this->command?->info(
            'Local: admin + Level 1 ready. Optional full demo: php artisan db:seed --class=Database\\Seeders\\DemoDataSeeder',
        );
    }
}
