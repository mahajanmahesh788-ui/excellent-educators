<?php

namespace App\Http\Requests\Api\V1\AdminRequests;

use Illuminate\Foundation\Http\FormRequest;

class ResolveAdminRequestRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        $note = $this->input('resolution_note', $this->input('message'));
        if (is_string($note)) {
            $note = trim($note);
        }

        $this->merge([
            'resolution_note' => $note,
        ]);
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'apply_action' => ['sometimes', 'boolean'],
            'reject' => ['sometimes', 'boolean'],
            'resolution_note' => ['required', 'string', 'min:1', 'max:2000'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'resolution_note.required' => 'Please write a message for the requester.',
        ];
    }
}
