<?php

namespace App\Http\Requests\Api\V1\Teacher;

use Illuminate\Foundation\Http\FormRequest;

class RecordAssessmentScoresRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'scores' => ['required', 'array', 'min:1'],
            'scores.*.student_id' => ['required', 'ulid', 'exists:student_profiles,id'],
            'scores.*.score' => ['nullable', 'numeric', 'min:0'],
            'scores.*.notes' => ['nullable', 'string', 'max:500'],
        ];
    }
}
