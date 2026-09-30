<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        // System bootstrap only — safe for production (no people, no demo journeys).
        $this->call([
            RoleSeeder::class,
            DimensionSeeder::class,
            LoginPageContentSeeder::class,
            SitePageSeeder::class,
        ]);

        // Local/dev sample data only. Production stays empty; you add real users in the app.
        if (app()->environment('production')) {
            $this->command?->info('Production: skipped demo/admin seeders. Create your own admin after deploy.');

            return;
        }

        $this->call([
            AdminSeeder::class,
            LevelSeeder::class,
            DemoTeacherSeeder::class,
            DemoWeeklyLearningSeeder::class,
            DemoStudentJourneySeeder::class,
        ]);
    }
}
