<?php

namespace App\Actions\SubAdmins;

use App\Enums\AdminAccountType;
use App\Enums\UserStatus;
use App\Models\User;
use App\Support\SyncUserAccess;
use Illuminate\Support\Facades\DB;

class UpdateSubAdmin
{
    /**
     * @param  array<string, mixed>  $input
     */
    public function execute(User $user, array $input): User
    {
        return DB::transaction(function () use ($user, $input): User {
            $user->fill([
                'name' => $input['name'] ?? $user->name,
                'email' => $input['email'] ?? $user->email,
            ]);

            if (! empty($input['password'])) {
                $user->password = $input['password'];
            }

            if (isset($input['status'])) {
                $next = UserStatus::from($input['status']);
                $user->status = $next;
            }

            $user->save();

            if (isset($input['status'])) {
                if ($user->status === UserStatus::Active) {
                    SyncUserAccess::activate($user);
                } else {
                    SyncUserAccess::deactivate($user);
                }
            }

            $profile = $user->adminProfile()->firstOrCreate(['user_id' => $user->id]);
            $type = array_key_exists('type', $input)
                ? (AdminAccountType::tryFrom((string) $input['type']) ?? AdminAccountType::Admin)
                : ($profile->type ?? AdminAccountType::Admin);

            $profile->fill([
                'phone' => array_key_exists('phone', $input) ? $input['phone'] : $profile->phone,
                'gender' => array_key_exists('gender', $input) ? $input['gender'] : $profile->gender,
                'type' => $type,
            ]);
            $profile->save();

            if (array_key_exists('permissions', $input) || array_key_exists('type', $input)) {
                $permissions = $input['permissions'] ?? $user->getPermissionNames()->mapWithKeys(
                    fn (string $name) => [$name => true],
                )->all();
                $user->syncPermissions(CreateSubAdmin::enabledKeys($permissions, $type));
            }

            return $user->load('adminProfile', 'roles', 'permissions');
        });
    }
}
