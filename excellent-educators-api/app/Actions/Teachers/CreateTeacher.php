<?php

namespace App\Actions\Teachers;

use App\Enums\ProfileStatus;
use App\Enums\RoleName;
use App\Enums\TeacherWorkType;
use App\Enums\UserStatus;
use App\Exceptions\ApiException;
use App\Models\TeacherProfile;
use App\Models\User;
use App\Scheduling\TeacherAvailability;
use App\Support\ErrorCode;
use Illuminate\Support\Facades\DB;

class CreateTeacher
{
    /**
     * @param  array{
     *     name: string,
     *     email: string,
     *     password: string,
     *     employee_code?: string|null,
     *     phone?: string|null,
     *     whatsapp_number?: string|null,
     *     address?: string|null,
     *     roles?: array<int, string>
     * }  $input
     */
    public function execute(array $input): TeacherProfile
    {
        $roles = ! empty($input['roles']) ? $input['roles'] : [RoleName::MasterTeacher->value];
        $allowed = [RoleName::CommonTeacher->value, RoleName::MasterTeacher->value];
        foreach ($roles as $role) {
            if (! in_array($role, $allowed, true)) {
                throw new ApiException(
                    ErrorCode::VALIDATION_ERROR,
                    'Teachers may only be assigned common_teacher and/or master_teacher.',
                    422,
                    ['roles' => ['Invalid role.']],
                );
            }
        }

        return DB::transaction(function () use ($input, $roles): TeacherProfile {
            $user = User::query()->create([
                'name' => $input['name'],
                'email' => $input['email'],
                'password' => $input['password'],
                'status' => UserStatus::Active,
            ]);
            $user->syncRoles($roles);

            $profile = TeacherProfile::query()->create([
                'user_id' => $user->id,
                'employee_code' => $input['employee_code'] ?? null,
                'full_name' => $input['name'],
                'phone' => $input['phone'] ?? null,
                'whatsapp_number' => $input['whatsapp_number'] ?? null,
                'address' => $input['address'] ?? null,
                'status' => ProfileStatus::Active,
                'work_type' => TeacherWorkType::FullTime->value,
            ]);
            app(TeacherAvailability::class)->seedDefaultWeekly($profile);

            return $profile;
        });
    }
}
