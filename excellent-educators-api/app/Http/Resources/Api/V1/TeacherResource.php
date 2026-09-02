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
        return [
            'id' => $this->id,
            'full_name' => $this->full_name,
            'email' => $this->user?->email,
            'phone' => $this->phone,
            'whatsapp_number' => $this->whatsapp_number,
            'employee_code' => $this->employee_code,
            'status' => $this->status?->value ?? $this->status,
            'created_at' => $this->created_at?->toIso8601String(),
            'roles' => $this->user?->getRoleNames()->values()->all() ?? [],
            'active_batch_count' => $this->whenCounted('activeBatchAssignments'),
            'active_mentee_count' => $this->whenCounted('activeMasterTeacherAssignments'),
            'career_compass_levels' => $this->whenLoaded(
                'activeBatchAssignments',
                fn () => $this->activeBatchAssignments
                    ->map(fn ($assignment) => $assignment->batch?->careerCompassLevel)
                    ->filter()
                    ->unique('id')
                    ->map(fn ($level) => CareerCompassLevelResource::make($level)->resolve())
                    ->values()
                    ->all(),
            ),
        ];
    }
}
