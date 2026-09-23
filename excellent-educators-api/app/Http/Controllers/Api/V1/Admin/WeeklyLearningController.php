<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Actions\Learning\SyncWeeklyOptionDimensionCodes;
use App\Http\Controllers\Api\V1\Concerns\AuthorizesLearningJournal;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Learning\UpsertWeeklyLearningRequest;
use App\Models\AcademicLevel;
use App\Models\WeeklyLearning;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class WeeklyLearningController extends Controller
{
    use AuthorizesLearningJournal;

    public function index(AcademicLevel $level): JsonResponse
    {
        $this->assertCanManageWeeklyLearning(request());

        $units = WeeklyLearning::query()
            ->with('questions.options.dimensionCodes')
            ->where('level_id', $level->id)
            ->orderBy('week_number')
            ->get();

        return ApiResponse::success('Weekly learning fetched successfully.', $units->map(fn ($unit) => $this->serialize($unit))->all());
    }

    public function upsert(
        UpsertWeeklyLearningRequest $request,
        AcademicLevel $level,
        SyncWeeklyOptionDimensionCodes $syncDimensionCodes,
    ): JsonResponse {
        $this->assertCanManageWeeklyLearning($request);
        $data = $request->validated();

        $unit = DB::transaction(function () use ($level, $data, $syncDimensionCodes): WeeklyLearning {
            $unit = WeeklyLearning::query()->updateOrCreate(
                [
                    'level_id' => $level->id,
                    'week_number' => $data['week_number'],
                ],
                [
                    'video_url' => $data['video_url'],
                ],
            );

            $unit->questions()->delete();

            foreach ($data['questions'] as $index => $questionData) {
                $question = $unit->questions()->create([
                    'question_text' => $questionData['question_text'],
                    'display_order' => $index + 1,
                ]);
                foreach ($questionData['options'] as $optionIndex => $optionData) {
                    $option = $question->options()->create([
                        'option_text' => $optionData['option_text'],
                        'display_order' => $optionIndex + 1,
                    ]);
                    $syncDimensionCodes->execute($option, $optionData['dimension_codes']);
                }
            }

            return $unit->fresh(['questions.options.dimensionCodes']);
        });

        return ApiResponse::success('Weekly learning saved successfully.', $this->serialize($unit));
    }

    /**
     * @return array<string, mixed>
     */
    private function serialize(WeeklyLearning $unit): array
    {
        return [
            'id' => $unit->id,
            'level_id' => $unit->level_id,
            'week_number' => $unit->week_number,
            'video_url' => $unit->video_url,
            'questions' => $unit->questions->map(fn ($question) => [
                'id' => $question->id,
                'question_text' => $question->question_text,
                'display_order' => $question->display_order,
                'options' => $question->options->map(fn ($option) => [
                    'id' => $option->id,
                    'option_text' => $option->option_text,
                    'display_order' => $option->display_order,
                    'dimension_codes' => $option->dimensionCodes
                        ->map(fn ($dimension) => $dimension->dimension_code->value)
                        ->values()
                        ->all(),
                    'dimension_names' => $option->dimensionCodes
                        ->map(fn ($dimension) => $dimension->dimension_code->label())
                        ->values()
                        ->all(),
                ])->values()->all(),
            ])->values()->all(),
        ];
    }
}
