<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Actions\Learning\SyncWeeklyOptionDimensionCodes;
use App\Enums\WeeklyQuestionSection;
use App\Enums\WeeklyQuestionType;
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
            $paragraph = trim((string) ($data['comprehension_paragraph'] ?? ''));
            $comprehensionQuestions = $data['comprehension_questions'] ?? [];
            if ($paragraph === '' || ! is_array($comprehensionQuestions) || $comprehensionQuestions === []) {
                $paragraph = null;
                $comprehensionQuestions = [];
            }

            $unit = WeeklyLearning::query()->updateOrCreate(
                [
                    'level_id' => $level->id,
                    'week_number' => $data['week_number'],
                ],
                [
                    'video_url' => $data['video_url'],
                    'video_title' => filled($data['video_title'] ?? null)
                        ? trim((string) $data['video_title'])
                        : null,
                    'comprehension_paragraph' => $paragraph,
                ],
            );

            $unit->questions()->delete();

            $order = 0;
            foreach ($data['questions'] as $questionData) {
                $order++;
                $this->createQuestion(
                    $unit,
                    $questionData,
                    WeeklyQuestionSection::Main,
                    $order,
                    $syncDimensionCodes,
                );
            }

            foreach ($comprehensionQuestions as $questionData) {
                $order++;
                $this->createQuestion(
                    $unit,
                    $questionData,
                    WeeklyQuestionSection::Comprehension,
                    $order,
                    $syncDimensionCodes,
                );
            }

            return $unit->fresh(['questions.options.dimensionCodes']);
        });

        return ApiResponse::success('Weekly learning saved successfully.', $this->serialize($unit));
    }

    /**
     * @param  array<string, mixed>  $questionData
     */
    private function createQuestion(
        WeeklyLearning $unit,
        array $questionData,
        WeeklyQuestionSection $section,
        int $displayOrder,
        SyncWeeklyOptionDimensionCodes $syncDimensionCodes,
    ): void {
        $type = WeeklyQuestionType::from($questionData['question_type']);
        $question = $unit->questions()->create([
            'question_text' => $questionData['question_text'],
            'question_type' => $type,
            'section' => $section,
            'display_order' => $displayOrder,
        ]);

        if ($type !== WeeklyQuestionType::Options) {
            return;
        }

        foreach ($questionData['options'] ?? [] as $optionIndex => $optionData) {
            $option = $question->options()->create([
                'option_text' => $optionData['option_text'],
                'display_order' => $optionIndex + 1,
            ]);
            $syncDimensionCodes->execute($option, $optionData['dimension_codes']);
        }
    }

    /**
     * @return array<string, mixed>
     */
    private function serialize(WeeklyLearning $unit): array
    {
        $main = $unit->questions
            ->filter(fn ($question) => ($question->section ?? WeeklyQuestionSection::Main) === WeeklyQuestionSection::Main)
            ->values();
        $comprehension = $unit->questions
            ->filter(fn ($question) => $question->section === WeeklyQuestionSection::Comprehension)
            ->values();

        return [
            'id' => $unit->id,
            'level_id' => $unit->level_id,
            'week_number' => $unit->week_number,
            'video_url' => $unit->video_url,
            'video_title' => $unit->video_title,
            'comprehension_paragraph' => $unit->comprehension_paragraph,
            'questions' => $main->map(fn ($question) => $this->serializeQuestion($question))->values()->all(),
            'comprehension_questions' => $comprehension->map(fn ($question) => $this->serializeQuestion($question))->values()->all(),
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function serializeQuestion($question): array
    {
        return [
            'id' => $question->id,
            'question_text' => $question->question_text,
            'question_type' => $question->question_type->value,
            'section' => ($question->section ?? WeeklyQuestionSection::Main)->value,
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
        ];
    }
}
