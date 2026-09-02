<?php

namespace App\Http\Resources\Api\V1;

use App\Models\AdminRequest;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin AdminRequest
 */
class AdminRequestResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'subtitle' => $this->subtitle,
            'description' => $this->description,
            'status' => $this->status?->value ?? $this->status,
            'requester_type' => $this->requester_type?->value ?? $this->requester_type,
            'request_type' => $this->request_type?->value ?? $this->request_type ?? 'general',
            'student' => $this->whenLoaded('student', fn () => $this->student === null ? null : [
                'id' => $this->student->id,
                'full_name' => $this->student->full_name,
                'student_code' => $this->student->student_code,
            ]),
            'batch' => $this->whenLoaded('batch', fn () => $this->batch === null ? null : [
                'id' => $this->batch->id,
                'name' => $this->batch->name,
            ]),
            'requester' => $this->whenLoaded('user', fn () => [
                'id' => $this->user?->id,
                'name' => $this->user?->name,
                'email' => $this->user?->email,
                'phone' => $this->user?->studentProfile?->phone ?? $this->user?->teacherProfile?->phone,
            ]),
            'resolved_at' => $this->resolved_at?->toIso8601String(),
            'resolved_by' => $this->whenLoaded('resolvedBy', fn () => $this->resolvedBy === null ? null : [
                'id' => $this->resolvedBy->id,
                'name' => $this->resolvedBy->name,
            ]),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
