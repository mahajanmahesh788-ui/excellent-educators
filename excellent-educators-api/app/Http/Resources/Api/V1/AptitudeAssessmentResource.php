<?php

namespace App\Http\Resources\Api\V1;

use App\Enums\DimensionCode;
use App\Models\AptitudeAssessment;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin AptitudeAssessment
 */
class AptitudeAssessmentResource extends JsonResource
{
    public function __construct($resource, private readonly bool $includeDimensionCodes = true)
    {
        parent::__construct($resource);
    }

    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'description' => $this->description,
            'status' => $this->status?->value ?? $this->status,
            'questions_count' => $this->questions_count ?? $this->questions->count(),
            'submitted_attempts_count' => $this->submitted_attempts_count
                ?? ($this->relationLoaded('submittedAttempts') ? $this->submittedAttempts->count() : 0),
            'questions' => $this->whenLoaded('questions', fn () => $this->questions->map(function ($question) {
                return [
                    'id' => $question->id,
                    'question_text' => $question->question_text,
                    'display_order' => $question->display_order,
                    'options' => $question->options->map(function ($option) {
                        $payload = [
                            'id' => $option->id,
                            'option_text' => $option->option_text,
                            'display_order' => $option->display_order,
                        ];

                        if ($this->includeDimensionCodes) {
                            $codes = $option->dimensionCodes
                                ->map(function ($row) {
                                    return $row->dimension_code instanceof DimensionCode
                                        ? $row->dimension_code->value
                                        : (string) $row->dimension_code;
                                })
                                ->values()
                                ->all();

                            $payload['dimension_codes'] = $codes;
                            $payload['dimension_names'] = array_map(
                                fn (string $code) => DimensionCode::tryFrom($code)?->label() ?? $code,
                                $codes,
                            );
                        }

                        return $payload;
                    })->values()->all(),
                ];
            })->values()->all()),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
