<?php

namespace App\Actions\Students;

use App\Enums\ProfileStatus;
use App\Exceptions\ApiException;
use App\Models\StudentProfile;
use App\Support\ErrorCode;

class UpdateStudent
{
    /**
     * @param  array<string, mixed>  $input
     */
    public function execute(StudentProfile $student, array $input): StudentProfile
    {
        if (array_key_exists('student_code', $input)) {
            throw new ApiException(
                ErrorCode::STUDENT_CODE_IMMUTABLE,
                'Student ID cannot be changed.',
                422,
            );
        }

        if (isset($input['class_grade'])) {
            $grade = (int) $input['class_grade'];
            if ($grade < 5 || $grade > 12) {
                throw new ApiException(
                    ErrorCode::VALIDATION_ERROR,
                    "Class {$grade} is not valid. Must be between 5 and 12.",
                    422,
                    ['class_grade' => ['Must be between 5 and 12.']],
                );
            }
            $input['class_grade'] = $grade;
        }

        $student->fill([
            'full_name' => $input['name'] ?? $student->full_name,
            'phone' => $input['phone'] ?? $student->phone,
            'whatsapp_number' => array_key_exists('whatsapp_number', $input) ? $input['whatsapp_number'] : $student->whatsapp_number,
            'address' => array_key_exists('address', $input) ? $input['address'] : $student->address,
            'class_grade' => $input['class_grade'] ?? $student->class_grade,
            'guardian_name' => array_key_exists('guardian_name', $input) ? $input['guardian_name'] : $student->guardian_name,
            'guardian_phone' => array_key_exists('guardian_phone', $input) ? $input['guardian_phone'] : $student->guardian_phone,
            'status' => $input['status'] ?? $student->status,
        ]);
        $student->save();

        if (isset($input['name'])) {
            $student->user->update(['name' => $input['name']]);
        }

        if (isset($input['status']) && $input['status'] === ProfileStatus::Inactive->value) {
            $student->user->update(['status' => 'inactive']);
        }

        return $student->refresh();
    }
}
