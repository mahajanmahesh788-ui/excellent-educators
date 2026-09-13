<?php

namespace App\Http\Requests\Api\V1\Learning;

use Illuminate\Foundation\Http\FormRequest;

class SubmitWeeklyAssignmentRequest extends FormRequest
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
            'answers' => ['required', 'array', 'min:1'],
            'answers.*.question_id' => ['required', 'ulid'],
            'answers.*.option_id' => ['required', 'ulid'],
        ];
    }
}
