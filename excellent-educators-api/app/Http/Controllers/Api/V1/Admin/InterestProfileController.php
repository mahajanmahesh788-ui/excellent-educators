<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Enums\InterestOptionSource;
use App\Http\Controllers\Api\V1\Concerns\AuthorizesLearningJournal;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Onboarding\UpsertInterestQuestionsRequest;
use App\Models\InterestOption;
use App\Models\InterestQuestion;
use App\Support\ApiResponse;
use App\Support\InterestOptionNormalizer;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class InterestProfileController extends Controller
{
    use AuthorizesLearningJournal;

    public function index(): JsonResponse
    {
        $this->assertCanManageWeeklyLearning(request());

        $questions = InterestQuestion::query()
            ->with('options')
            ->orderBy('display_order')
            ->get();

        return ApiResponse::success(
            'Interest questions fetched successfully.',
            $questions->map(fn (InterestQuestion $question) => $this->serialize($question))->all(),
        );
    }

    public function upsert(UpsertInterestQuestionsRequest $request): JsonResponse
    {
        $this->assertCanManageWeeklyLearning($request);
        $data = $request->validated();

        $questions = DB::transaction(function () use ($data) {
            $keptQuestionIds = [];

            foreach (array_values($data['questions']) as $index => $questionData) {
                $question = null;
                $incomingId = $questionData['id'] ?? null;
                if (is_string($incomingId) && $incomingId !== '') {
                    $question = InterestQuestion::query()->find($incomingId);
                }

                if ($question === null) {
                    $question = InterestQuestion::query()->create([
                        'question_text' => $questionData['question_text'],
                        'allow_other' => (bool) ($questionData['allow_other'] ?? true),
                        'max_selections' => (int) ($questionData['max_selections'] ?? 5),
                        'display_order' => $index + 1,
                        'is_active' => (bool) ($questionData['is_active'] ?? true),
                    ]);
                } else {
                    $question->forceFill([
                        'question_text' => $questionData['question_text'],
                        'allow_other' => (bool) ($questionData['allow_other'] ?? true),
                        'max_selections' => (int) ($questionData['max_selections'] ?? 5),
                        'display_order' => $index + 1,
                        'is_active' => (bool) ($questionData['is_active'] ?? true),
                    ])->save();
                }

                $keptQuestionIds[] = $question->id;
                $this->syncAdminOptions($question, $questionData['options'] ?? []);
            }

            InterestQuestion::query()
                ->whereNotIn('id', $keptQuestionIds)
                ->update(['is_active' => false]);

            return InterestQuestion::query()
                ->with('options')
                ->whereIn('id', $keptQuestionIds)
                ->orderBy('display_order')
                ->get();
        });

        return ApiResponse::success(
            'Interest questions saved successfully.',
            $questions->map(fn (InterestQuestion $question) => $this->serialize($question))->all(),
        );
    }

    /**
     * @param  list<array{id?: string, option_text: string, is_active?: bool}>  $optionsData
     */
    private function syncAdminOptions(InterestQuestion $question, array $optionsData): void
    {
        $keptAdminOptionIds = [];
        $seenKeys = [];

        foreach (array_values($optionsData) as $optionIndex => $optionData) {
            $label = trim((string) $optionData['option_text']);
            $key = InterestOptionNormalizer::normalize($label);
            if ($key === '' || isset($seenKeys[$key])) {
                continue;
            }
            $seenKeys[$key] = true;

            $option = null;
            $incomingId = $optionData['id'] ?? null;
            if (is_string($incomingId) && $incomingId !== '') {
                $option = InterestOption::query()
                    ->where('interest_question_id', $question->id)
                    ->where('id', $incomingId)
                    ->first();
            }

            if ($option === null) {
                $option = InterestOption::query()
                    ->where('interest_question_id', $question->id)
                    ->where('normalized_key', $key)
                    ->first();
            }

            if ($option === null) {
                $option = InterestOption::query()->create([
                    'interest_question_id' => $question->id,
                    'option_text' => mb_substr($label, 0, 100),
                    'normalized_key' => $key,
                    'source' => InterestOptionSource::Admin,
                    'display_order' => $optionIndex + 1,
                    'is_active' => (bool) ($optionData['is_active'] ?? true),
                    'usage_count' => 0,
                ]);
            } else {
                $option->forceFill([
                    'option_text' => mb_substr($label, 0, 100),
                    'normalized_key' => $key,
                    'display_order' => $optionIndex + 1,
                    'is_active' => (bool) ($optionData['is_active'] ?? true),
                    // Promote back to admin if re-saved from the editor.
                    'source' => InterestOptionSource::Admin,
                ])->save();
            }

            $keptAdminOptionIds[] = $option->id;
        }

        // Deactivate removed admin options; never wipe student-sourced crowd options.
        InterestOption::query()
            ->where('interest_question_id', $question->id)
            ->where('source', InterestOptionSource::Admin)
            ->whereNotIn('id', $keptAdminOptionIds)
            ->update(['is_active' => false]);
    }

    /**
     * @return array<string, mixed>
     */
    private function serialize(InterestQuestion $question): array
    {
        return [
            'id' => $question->id,
            'question_text' => $question->question_text,
            'allow_other' => $question->allow_other,
            'max_selections' => $question->max_selections,
            'display_order' => $question->display_order,
            'is_active' => $question->is_active,
            'options' => $question->options->map(fn ($option) => [
                'id' => $option->id,
                'option_text' => $option->option_text,
                'source' => $option->source->value,
                'display_order' => $option->display_order,
                'is_active' => $option->is_active,
                'usage_count' => $option->usage_count,
            ])->values()->all(),
        ];
    }
}
