<?php

namespace App\Actions\SubAdmins;

use App\Enums\UserStatus;
use App\Models\User;
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
                $user->status = UserStatus::from($input['status']);
            }

            $user->save();

            $profile = $user->adminProfile()->firstOrCreate(['user_id' => $user->id]);
            $profile->fill([
                'phone' => array_key_exists('phone', $input) ? $input['phone'] : $profile->phone,
                'gender' => array_key_exists('gender', $input) ? $input['gender'] : $profile->gender,
            ]);
            $profile->save();

            if (array_key_exists('permissions', $input)) {
                $user->syncPermissions(CreateSubAdmin::enabledKeys($input['permissions']));
            }

            return $user->load('adminProfile', 'roles', 'permissions');
        });
    }
}
