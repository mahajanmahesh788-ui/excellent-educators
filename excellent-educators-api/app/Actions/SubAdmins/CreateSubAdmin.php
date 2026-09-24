<?php

namespace App\Actions\SubAdmins;

use App\Enums\AdminAccountType;
use App\Enums\PermissionName;
use App\Enums\RoleName;
use App\Enums\UserStatus;
use App\Models\AdminProfile;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class CreateSubAdmin
{
    /**
     * @param  array<string, mixed>  $input
     */
    public function execute(array $input): User
    {
        return DB::transaction(function () use ($input): User {
            $type = AdminAccountType::tryFrom((string) ($input['type'] ?? AdminAccountType::Admin->value))
                ?? AdminAccountType::Admin;

            $user = User::query()->create([
                'name' => $input['name'],
                'email' => $input['email'],
                'password' => $input['password'],
                'status' => UserStatus::Active,
            ]);
            $user->assignRole(RoleName::SubAdmin->value);

            AdminProfile::query()->create([
                'user_id' => $user->id,
                'phone' => $input['phone'] ?? null,
                'gender' => $input['gender'] ?? null,
                'type' => $type,
            ]);

            $user->syncPermissions(self::enabledKeys($input['permissions'] ?? [], $type));

            return $user->load('adminProfile', 'roles', 'permissions');
        });
    }

    /**
     * @return list<string>
     */
    public static function enabledKeys(mixed $permissions, AdminAccountType $type = AdminAccountType::Admin): array
    {
        $allowed = array_map(
            fn (PermissionName $p) => $p->value,
            $type->isAgent() ? PermissionName::agentToggles() : PermissionName::subAdminToggles(),
        );

        if (is_array($permissions) && array_is_list($permissions)) {
            return array_values(array_intersect($allowed, array_map('strval', $permissions)));
        }

        if (! is_array($permissions)) {
            return [];
        }

        $enabled = [];
        foreach ($permissions as $key => $value) {
            if (in_array((string) $key, $allowed, true) && filter_var($value, FILTER_VALIDATE_BOOLEAN)) {
                $enabled[] = (string) $key;
            }
        }

        return $enabled;
    }
}
