<?php

namespace App\Http\Resources\Api\V1;

use App\Models\TeacherProfile;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin TeacherProfile
 */
class TeacherResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $academicLevels = $this->relationLoaded('academicLevels')
            ? $this->academicLevels
            : $this->academicLevels()->get();
        $assignedLevels = $academicLevels->pluck('name')->values()->all();

        return [
            'id' => $this->id,
            'full_name' => $this->full_name,
            'email' => $this->user?->email,
            'phone' => $this->phone,
            'whatsapp_number' => $this->whatsapp_number,
            'address' => $this->address,
            'employee_code' => $this->employee_code,
            'status' => $this->status?->value ?? $this->status,
            'work_type' => $this->work_type?->value ?? $this->work_type ?? 'full_time',
            'created_at' => $this->created_at?->toIso8601String(),
            'roles' => $this->user?->getRoleNames()->values()->all() ?? [],
            'assigned_levels' => $assignedLevels,
            'assigned_levels_count' => $this->academic_levels_count ?? $academicLevels->count(),
            'active_batch_count' => $this->whenCounted('activeBatchAssignments'),
            'active_mentee_count' => $this->whenCounted('activeMasterTeacherAssignments'),
        ];
    }
}
