<?php

namespace Database\Seeders;

use App\Models\CareerCompassLevel;
use Illuminate\Database\Seeder;

class CareerCompassLevelSeeder extends Seeder
{
    public function run(): void
    {
        $levels = [
            [
                'code' => 'cc1',
                'name' => 'Career Compass 1',
                'class_from' => 6,
                'class_to' => 8,
            ],
            [
                'code' => 'cc2',
                'name' => 'Career Compass 2',
                'class_from' => 9,
                'class_to' => 10,
            ],
            [
                'code' => 'cc3',
                'name' => 'Career Compass 3',
                'class_from' => 11,
                'class_to' => 12,
            ],
        ];

        foreach ($levels as $level) {
            CareerCompassLevel::query()->updateOrCreate(
                ['code' => $level['code']],
                $level,
            );
        }
    }
}
