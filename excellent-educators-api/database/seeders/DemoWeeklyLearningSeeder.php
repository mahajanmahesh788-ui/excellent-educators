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
        $syncDimensionCodes = app(SyncWeeklyOptionDimensionCodes::class);

        $this->seedLevelWeeks(
            levelName: 'Level 1',
            weeks: DemoSeedData::levelOneWeeklyLearnings(),
            syncDimensionCodes: $syncDimensionCodes,
        );

        $this->seedLevelWeeks(
            levelName: 'Level 2',
            weeks: DemoSeedData::levelTwoWeeklyLearnings(),
            syncDimensionCodes: $syncDimensionCodes,
        );
    }

    /**
     * @param  list<array{week_number: int, video_url: string, comprehension_paragraph?: string, questions: list<array<string, mixed>>}>  $weeks
     */
    private function seedLevelWeeks(
        string $levelName,
        array $weeks,
        SyncWeeklyOptionDimensionCodes $syncDimensionCodes,
    ): void {
        $level = AcademicLevel::query()->where('name', $levelName)->first();
        if ($level === null) {
            $this->command?->warn("{$levelName} missing — run LevelSeeder first. Skipping weekly learning demo.");

            return;
        }

        foreach ($weeks as $week) {
            DB::transaction(function () use ($level, $week, $syncDimensionCodes): void {
                $unit = WeeklyLearning::query()->updateOrCreate(
                    [
                        'level_id' => $level->id,
                        'week_number' => $week['week_number'],
                    ],
                    [
                        'video_url' => $week['video_url'],
                        'video_title' => $week['video_title'] ?? null,
                        'comprehension_paragraph' => $week['comprehension_paragraph'] ?? null,
                    ],
                );

                $unit->questions()->delete();

                foreach ($week['questions'] as $questionIndex => $questionData) {
                    $question = $unit->questions()->create([
                        'question_text' => $questionData['question_text'],
                        'question_type' => $questionData['question_type'] ?? 'options',
                        'display_order' => $questionIndex + 1,
                    ]);

                    foreach ($questionData['options'] ?? [] as $optionIndex => $optionData) {
                        $option = $question->options()->create([
                            'option_text' => $optionData['option_text'],
                            'display_order' => $optionIndex + 1,
                        ]);
                        $syncDimensionCodes->execute($option, $optionData['dimension_codes']);
                    }
                }
            });
        }

        $this->command?->info("Seeded {$levelName} weekly learning (".count($weeks).' weeks).');
    }
}
