<?php

namespace App\Http\Requests\Api\V1\Learning;

use App\Support\OptionDimensionCodeRules;
use Illuminate\Foundation\Http\FormRequest;

class UpsertWeeklyLearningRequest extends FormRequest
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
        return array_merge([
            'week_number' => ['required', 'integer', 'min:1', 'max:52'],
            'video_url' => ['required', 'url', 'max:2048'],
            'questions' => ['required', 'array', 'min:1'],
            'questions.*.question_text' => ['required', 'string', 'max:2000'],
            'questions.*.options' => ['required', 'array', 'min:2'],
            'questions.*.options.*.option_text' => ['required', 'string', 'max:500'],
        ], OptionDimensionCodeRules::forField('questions.*.options.*.dimension_codes'));
    }
}
