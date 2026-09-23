<?php

namespace Database\Seeders;

use App\Actions\Learning\SyncWeeklyOptionDimensionCodes;
use App\Models\AcademicLevel;
use App\Models\WeeklyLearning;
use Database\Seeders\Support\DemoSeedData;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class DemoWeeklyLearningSeeder extends Seeder
{
    public function run(): void
    {
        $level = AcademicLevel::query()->where('name', 'Level 1')->first();
        if ($level === null) {
            $this->command?->warn('Level 1 missing — run LevelSeeder first. Skipping weekly learning demo.');

            return;
        }

        $syncDimensionCodes = app(SyncWeeklyOptionDimensionCodes::class);

        foreach (DemoSeedData::levelOneWeeklyLearnings() as $week) {
            DB::transaction(function () use ($level, $week, $syncDimensionCodes): void {
                $unit = WeeklyLearning::query()->updateOrCreate(
                    [
                        'level_id' => $level->id,
                        'week_number' => $week['week_number'],
                    ],
                    [
                        'video_url' => $week['video_url'],
                    ],
                );

                $unit->questions()->delete();

                foreach ($week['questions'] as $questionIndex => $questionData) {
                    $question = $unit->questions()->create([
                        'question_text' => $questionData['question_text'],
                        'display_order' => $questionIndex + 1,
                    ]);

                    foreach ($questionData['options'] as $optionIndex => $optionData) {
                        $option = $question->options()->create([
                            'option_text' => $optionData['option_text'],
                            'display_order' => $optionIndex + 1,
                        ]);
                        $syncDimensionCodes->execute($option, $optionData['dimension_codes']);
                    }
                }
            });
        }
    }
}
