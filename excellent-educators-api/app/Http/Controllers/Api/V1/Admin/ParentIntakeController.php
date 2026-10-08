<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Enums\OnboardingQuestionType;
use App\Http\Controllers\Api\V1\Concerns\AuthorizesLearningJournal;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Onboarding\UpsertParentQuestionsRequest;
use App\Models\ParentOption;
use App\Models\ParentQuestion;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class ParentIntakeController extends Controller
{
    use AuthorizesLearningJournal;

    public function index(): JsonResponse
    {
        $this->assertCanManageWeeklyLearning(request());

        $questions = ParentQuestion::query()
            ->with('options')
            ->orderBy('display_order')
            ->get();

        return ApiResponse::success(
            'Parent questions fetched successfully.',
            $questions->map(fn (ParentQuestion $question) => $this->serialize($question))->all(),
        );
    }

    public function upsert(UpsertParentQuestionsRequest $request): JsonResponse
    {
        $this->assertCanManageWeeklyLearning($request);
        $data = $request->validated();

        $questions = DB::transaction(function () use ($data) {
            $keptQuestionIds = [];

            foreach (array_values($data['questions']) as $index => $questionData) {
                $type = OnboardingQuestionType::from($questionData['question_type']);
                $question = null;
                $incomingId = $questionData['id'] ?? null;
                if (is_string($incomingId) && $incomingId !== '') {
                    $question = ParentQuestion::query()->find($incomingId);
                }

                if ($question === null) {
                    $question = ParentQuestion::query()->create([
                        'question_text' => $questionData['question_text'],
                        'question_type' => $type,
                        'display_order' => $index + 1,
                        'is_active' => (bool) ($questionData['is_active'] ?? true),
                    ]);
                } else {
                    $question->forceFill([
                        'question_text' => $questionData['question_text'],
                        'question_type' => $type,
                        'display_order' => $index + 1,
                        'is_active' => (bool) ($questionData['is_active'] ?? true),
                    ])->save();
                }

                $keptQuestionIds[] = $question->id;
                $this->syncOptions($question, $type, $questionData['options'] ?? []);
            }

            ParentQuestion::query()
                ->whereNotIn('id', $keptQuestionIds)
                ->update(['is_active' => false]);

            return ParentQuestion::query()
                ->with('options')
                ->whereIn('id', $keptQuestionIds)
                ->orderBy('display_order')
                ->get();
        });

        return ApiResponse::success(
            'Parent questions saved successfully.',
            $questions->map(fn (ParentQuestion $question) => $this->serialize($question))->all(),
        );
    }

    /**
     * @param  list<array{id?: string, option_text: string, is_active?: bool}>  $optionsData
     */
    private function syncOptions(ParentQuestion $question, OnboardingQuestionType $type, array $optionsData): void
    {
        if ($type !== OnboardingQuestionType::Options) {
            ParentOption::query()
                ->where('parent_question_id', $question->id)
                ->update(['is_active' => false]);

            return;
        }

        $keptIds = [];
        foreach (array_values($optionsData) as $optionIndex => $optionData) {
            $label = trim((string) $optionData['option_text']);
            if ($label === '') {
                continue;
            }

            $option = null;
            $incomingId = $optionData['id'] ?? null;
            if (is_string($incomingId) && $incomingId !== '') {
                $option = ParentOption::query()
                    ->where('parent_question_id', $question->id)
                    ->where('id', $incomingId)
                    ->first();
            }

            if ($option === null) {
                $option = ParentOption::query()->create([
                    'parent_question_id' => $question->id,
                    'option_text' => $label,
                    'display_order' => $optionIndex + 1,
                    'is_active' => (bool) ($optionData['is_active'] ?? true),
                ]);
            } else {
                $option->forceFill([
                    'option_text' => $label,
                    'display_order' => $optionIndex + 1,
                    'is_active' => (bool) ($optionData['is_active'] ?? true),
                ])->save();
            }

            $keptIds[] = $option->id;
        }

        ParentOption::query()
            ->where('parent_question_id', $question->id)
            ->whereNotIn('id', $keptIds)
            ->update(['is_active' => false]);
    }

    /**
     * @return array<string, mixed>
     */
    private function serialize(ParentQuestion $question): array
    {
        return [
            'id' => $question->id,
            'question_text' => $question->question_text,
            'question_type' => $question->question_type->value,
            'display_order' => $question->display_order,
            'is_active' => $question->is_active,
            'options' => $question->options->map(fn ($option) => [
                'id' => $option->id,
                'option_text' => $option->option_text,
                'display_order' => $option->display_order,
                'is_active' => $option->is_active,
            ])->values()->all(),
        ];
    }
}
