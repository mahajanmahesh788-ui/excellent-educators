<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

/**
 * Local/testing demo pack driven by {@see Support\DemoSeedData}.
 * Run after a clean: `php artisan app:clean-academic-data --force --seed`
 */
class DemoDataSeeder extends Seeder
{
    public function run(): void
    {
        $this->call([
            LevelSeeder::class,
            DemoAptitudeAssessmentSeeder::class,
            DemoTeacherSeeder::class,
            DemoWeeklyLearningSeeder::class,
            DemoStudentJourneySeeder::class,
        ]);
    }
}
