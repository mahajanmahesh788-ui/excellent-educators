<?php

namespace App\Http\Requests\Api\V1\Teacher;

use App\Support\MentorProfileRules;
use Illuminate\Foundation\Http\FormRequest;

class UpdateMentorProfileRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->teacherProfile !== null;
    }

    protected function prepareForValidation(): void
    {
        $merge = [];
        foreach (['photo_url', 'professional_title', 'bio', 'experience_summary'] as $field) {
            if ($this->exists($field) && is_string($this->input($field)) && trim((string) $this->input($field)) === '') {
                $merge[$field] = null;
            }
        }
        if ($merge !== []) {
            $this->merge($merge);
        }
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return MentorProfileRules::fields();
    }
}
