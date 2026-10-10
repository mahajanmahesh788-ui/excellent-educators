<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use RuntimeException;

/**
 * Local/testing demo pack driven by {@see Support\DemoSeedData}.
 * Run after a clean: `php artisan app:clean-academic-data --force --seed`
 */
class DemoDataSeeder extends Seeder
{
    public function run(): void
    {
        if (app()->environment('production')) {
            throw new RuntimeException('Refusing to seed demo data in production.');
        }

        $this->call([
            LevelSeeder::class,
            DemoAptitudeAssessmentSeeder::class,
            DemoTeacherSeeder::class,
            DemoWeeklyLearningSeeder::class,
            DemoStudentJourneySeeder::class,
        ]);
    }
}
