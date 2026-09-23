<?php

namespace App\Http\Resources\Api\V1;

use App\Enums\PermissionName;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin User
 */
class SubAdminResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $granted = $this->getPermissionNames()->all();
        $permissions = [];
        foreach (PermissionName::subAdminToggles() as $permission) {
            $permissions[$permission->value] = in_array($permission->value, $granted, true);
        }

        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'phone' => $this->adminProfile?->phone,
            'gender' => $this->adminProfile?->gender?->value ?? $this->adminProfile?->gender,
            'status' => $this->status?->value ?? $this->status,
            'permissions' => $permissions,
            'last_login_at' => $this->last_login_at?->toIso8601String(),
        ];
    }
}
