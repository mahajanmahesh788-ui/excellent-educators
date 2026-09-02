<?php

namespace App\Http\Resources\Api\V1;

use App\Enums\DimensionCode;
use App\Models\AptitudeAssessmentResult;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin AptitudeAssessmentResult
 */
class AptitudeAssessmentResultResource extends JsonResource
{
    public function __construct($resource, private readonly bool $includeCodes = false)
    {
        parent::__construct($resource);
    }

    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $attempt = $this->attempt;
        $assessment = $attempt?->assessment;

        $dimensions = $this->whenLoaded('dimensions', function () {
            return $this->dimensions
                ->sortBy(fn ($row) => array_search(
                    $row->dimension_code instanceof DimensionCode
                        ? $row->dimension_code->value
                        : (string) $row->dimension_code,
                    DimensionCode::values(),
                    true,
                ))
                ->map(function ($row) {
                    $code = $row->dimension_code instanceof DimensionCode
                        ? $row->dimension_code
                        : DimensionCode::tryFrom((string) $row->dimension_code);

                    $payload = [
                        'name' => $code?->label() ?? (string) $row->dimension_code,
                        'score' => (int) $row->score,
                    ];

                    if ($this->includeCodes) {
                        $payload['code'] = $code?->value;
                    }

                    return $payload;
                })
                ->values()
                ->all();
        });

        return [
            'id' => $this->id,
            'assessment' => $assessment === null ? null : [
                'id' => $assessment->id,
                'title' => $assessment->title,
            ],
            'career_compass_level' => $assessment?->careerCompassLevel === null
                ? null
                : CareerCompassLevelResource::make($assessment->careerCompassLevel)->resolve(),
            'student' => $this->whenLoaded('student', fn () => [
                'id' => $this->student->id,
                'full_name' => $this->student->full_name,
                'student_code' => $this->student->student_code,
            ]),
            'submitted_at' => $attempt?->submitted_at?->toIso8601String(),
            'calculated_at' => $this->calculated_at?->toIso8601String(),
            'dimensions' => $dimensions,
        ];
    }
}
