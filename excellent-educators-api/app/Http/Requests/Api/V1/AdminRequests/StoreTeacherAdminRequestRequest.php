<?php

namespace App\Http\Requests\Api\V1\AdminRequests;

use App\Enums\AdminRequestType;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreTeacherAdminRequestRequest extends FormRequest
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
        $type = AdminRequestType::tryFrom((string) $this->input('request_type', AdminRequestType::General->value))
            ?? AdminRequestType::General;

        return [
            'request_type' => ['sometimes', Rule::enum(AdminRequestType::class)],
            'student_id' => [
                Rule::requiredIf(in_array($type, [AdminRequestType::RemoveMentee, AdminRequestType::RemoveBatchStudent], true)),
                'nullable',
                'ulid',
                'exists:student_profiles,id',
            ],
            'batch_id' => [
                Rule::requiredIf($type === AdminRequestType::RemoveBatchStudent),
                'nullable',
                'ulid',
                'exists:batches,id',
            ],
            'reason' => ['nullable', 'string', 'max:5000'],
            'subtitle' => [
                Rule::requiredIf($type === AdminRequestType::General),
                'nullable',
                'string',
                'max:255',
            ],
            'description' => [
                Rule::requiredIf($type === AdminRequestType::General),
                'nullable',
                'string',
                'max:5000',
            ],
        ];
    }
}
