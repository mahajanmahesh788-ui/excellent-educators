<?php

namespace Database\Seeders;

use App\Models\AcademicLevel;
use App\Models\Batch;
use Illuminate\Database\Seeder;

class LevelSeeder extends Seeder
{
    public function run(): void
    {
        foreach ([1, 2] as $number) {
            $level = AcademicLevel::query()->firstOrCreate(
                ['number' => $number],
                [
                    'name' => "Level {$number}",
                    'academic_year' => (int) date('Y'),
                    'status' => 'active',
                ]
            );

            if ($level->number !== $number || $level->name !== "Level {$number}") {
                $level->forceFill([
                    'number' => $number,
                    'name' => "Level {$number}",
                    'status' => 'active',
                ])->save();
            }

            if (! Batch::query()->where('level_id', $level->id)->where('name', 'Batch 1')->exists()) {
                Batch::query()->create([
                    'level_id' => $level->id,
                    'name' => 'Batch 1',
                    'academic_year' => (int) date('Y'),
                    'year' => (int) date('Y'),
                    'month' => (int) date('n'),
                    'enrolled_watermark' => 0,
                    // Inactive until full (max students) or an admin activates it.
                    'status' => 'inactive',
                ]);
            }
        }
    }
}
