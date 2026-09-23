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
            'booking_id' => ['nullable', 'ulid'],
            'session_date' => ['nullable', 'date', 'before_or_equal:today'],
            'positive_points' => ['required', 'string', 'max:5000'],
            'areas_for_improvement' => ['nullable', 'string', 'max:5000'],
            'discussed_in_class' => ['nullable', 'string', 'max:5000'],
            'items' => ['required', 'array', 'min:10'],
            'items.*.target_type' => ['required', Rule::in([FeedbackTargetType::Dimension->value])],
            'items.*.target_id' => ['required', 'ulid'],
            'items.*.rating' => ['required', 'integer', 'min:1', 'max:10'],
        ];
    }
}
