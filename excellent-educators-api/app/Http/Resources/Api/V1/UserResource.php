<?php

namespace App\Http\Resources\Api\V1;

use App\Enums\PermissionName;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin User
 */
class UserResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'status' => $this->status?->value ?? $this->status,
            'roles' => $this->getRoleNames()->values()->all(),
            'permissions' => $this->permissionKeys(),
            'last_login_at' => $this->last_login_at?->toIso8601String(),
        ];
    }

    /**
     * @return list<string>
     */
    private function permissionKeys(): array
    {
        if ($this->isFullAdmin()) {
            return array_map(fn (PermissionName $permission) => $permission->value, PermissionName::cases());
        }

        return $this->getPermissionNames()->values()->all();
    }
}
