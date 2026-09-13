<?php

namespace Database\Seeders;

use App\Models\AcademicLevel;
use App\Models\Batch;
use Illuminate\Database\Seeder;

class LevelSeeder extends Seeder
{
    public function run(): void
    {
        $level = AcademicLevel::query()->firstOrCreate(
            ['name' => 'Level 1'],
            [
                'academic_year' => (int) date('Y'),
                'status' => 'active',
            ]
        );

        if (! Batch::query()->where('level_id', $level->id)->where('name', 'Batch 1')->exists()) {
            Batch::query()->create([
                'level_id' => $level->id,
                'name' => 'Batch 1',
                'academic_year' => (int) date('Y'),
                'year' => (int) date('Y'),
                'month' => (int) date('n'),
                'enrolled_watermark' => 0,
                'status' => 'active',
            ]);
        }
    }
}
