<?php

namespace App\Http\Resources\Api\V1;

use App\Models\AssessmentScore;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin AssessmentScore
 */
class AssessmentScoreResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'student_id' => $this->student_id,
            'version' => $this->version,
            'score' => $this->score === null ? null : (float) $this->score,
            'notes' => $this->notes,
            'scored_at' => $this->scored_at?->toIso8601String(),
            'student' => $this->whenLoaded('student', fn () => [
                'id' => $this->student->id,
                'full_name' => $this->student->full_name,
                'student_code' => $this->student->student_code,
            ]),
        ];
    }
}
