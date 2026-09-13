<?php

namespace App\Actions\Teachers;

use App\Enums\RoleName;
use App\Exceptions\ApiException;
use App\Models\TeacherProfile;
use App\Support\ErrorCode;

class UpdateTeacher
{
    /**
     * @param  array<string, mixed>  $input
     */
    public function execute(TeacherProfile $teacher, array $input): TeacherProfile
    {
        if (isset($input['roles'])) {
            $allowed = [RoleName::CommonTeacher->value, RoleName::MasterTeacher->value];
            foreach ($input['roles'] as $role) {
                if (! in_array($role, $allowed, true)) {
                    throw new ApiException(
                        ErrorCode::VALIDATION_ERROR,
                        'Teachers may only be assigned common_teacher and/or master_teacher.',
                        422,
                    );
                }
            }
            $teacher->user->syncRoles($input['roles']);
        }

        $teacher->fill([
            'full_name' => $input['name'] ?? $teacher->full_name,
            'employee_code' => array_key_exists('employee_code', $input) ? $input['employee_code'] : $teacher->employee_code,
            'phone' => array_key_exists('phone', $input) ? $input['phone'] : $teacher->phone,
            'whatsapp_number' => array_key_exists('whatsapp_number', $input) ? $input['whatsapp_number'] : $teacher->whatsapp_number,
            'address' => array_key_exists('address', $input) ? $input['address'] : $teacher->address,
            'status' => $input['status'] ?? $teacher->status,
            'work_type' => array_key_exists('work_type', $input) ? $input['work_type'] : $teacher->work_type,
        ]);
        $teacher->save();

        if (isset($input['name'])) {
            $teacher->user->update(['name' => $input['name']]);
        }

        return $teacher->refresh();
    }
}
