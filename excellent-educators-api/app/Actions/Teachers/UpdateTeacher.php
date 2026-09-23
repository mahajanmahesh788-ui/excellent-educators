<?php

namespace App\Actions\Teachers;

use App\Enums\RoleName;
use App\Models\TeacherProfile;
use App\Support\MentorProfileRules;

class UpdateTeacher
{
    /**
     * @param  array<string, mixed>  $input
     */
    public function execute(TeacherProfile $teacher, array $input): TeacherProfile
    {
        if (isset($input['roles'])) {
            $teacher->user->syncRoles([RoleName::MasterTeacher->value]);
        }

        $teacher->fill([
            'full_name' => $input['name'] ?? $teacher->full_name,
            'gender' => array_key_exists('gender', $input) ? $input['gender'] : $teacher->gender,
            'employee_code' => array_key_exists('employee_code', $input) ? $input['employee_code'] : $teacher->employee_code,
            'phone' => array_key_exists('phone', $input) ? $input['phone'] : $teacher->phone,
            'whatsapp_number' => array_key_exists('whatsapp_number', $input) ? $input['whatsapp_number'] : $teacher->whatsapp_number,
            'address' => array_key_exists('address', $input) ? $input['address'] : $teacher->address,
            'status' => $input['status'] ?? $teacher->status,
            'work_type' => array_key_exists('work_type', $input) ? $input['work_type'] : $teacher->work_type,
            ...MentorProfileRules::extract($input),
        ]);
        $teacher->save();

        if (isset($input['name'])) {
            $teacher->user->update(['name' => $input['name']]);
        }

        return $teacher->refresh();
    }
}
