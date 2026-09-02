<?php

namespace App\Http\Requests\Api\V1\MasterTeacher;

use App\Enums\FeedbackTargetType;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreMonthlyFeedbackRequest extends FormRequest
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
            'session_date' => ['required', 'date', 'before_or_equal:today'],
            'items' => ['required', 'array', 'min:1'],
            'items.*.target_type' => ['required', Rule::enum(FeedbackTargetType::class)],
            'items.*.target_id' => ['required', 'ulid'],
            'items.*.rating' => ['required', 'integer', 'min:1', 'max:10'],
            'items.*.positive_points' => ['nullable', 'string', 'max:5000'],
            'items.*.areas_for_improvement' => ['nullable', 'string', 'max:5000'],
            'items.*.recommended_next_action' => ['nullable', 'string', 'max:5000'],
        ];
    }
}
