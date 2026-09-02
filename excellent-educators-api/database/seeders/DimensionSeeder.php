<?php

namespace Database\Seeders;

use App\Enums\DimensionCode;
use App\Models\DevelopmentModule;
use App\Models\Dimension;
use App\Models\Skill;
use Illuminate\Database\Seeder;

class DimensionSeeder extends Seeder
{
    public function run(): void
    {
        foreach (DimensionCode::cases() as $index => $code) {
            $dimension = Dimension::query()->updateOrCreate(
                ['code' => $code->value],
                [
                    'name' => $code->label(),
                    'display_order' => $index + 1,
                ],
            );

            $module = DevelopmentModule::query()->updateOrCreate(
                [
                    'dimension_id' => $dimension->id,
                    'name' => $code->label().' foundations',
                ],
                ['display_order' => 1],
            );

            Skill::query()->updateOrCreate(
                [
                    'module_id' => $module->id,
                    'name' => $code->label().' practice',
                ],
                ['display_order' => 1],
            );
        }
    }
}
