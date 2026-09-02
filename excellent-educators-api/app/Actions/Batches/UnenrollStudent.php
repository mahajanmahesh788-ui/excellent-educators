<?php

namespace App\Actions\Batches;

use App\Enums\ProfileStatus;
use App\Exceptions\ApiException;
use App\Models\Batch;
use App\Models\BatchStudent;
use App\Models\StudentProfile;
use App\Support\ErrorCode;

class UnenrollStudent
{
    public function execute(Batch $batch, StudentProfile $student): BatchStudent
    {
        $enrollment = BatchStudent::query()
            ->where('batch_id', $batch->id)
            ->where('student_id', $student->id)
            ->whereNull('left_at')
            ->where('status', ProfileStatus::Active->value)
            ->first();

        if ($enrollment === null) {
            throw new ApiException(
                ErrorCode::NOT_FOUND,
                'This student is not actively enrolled in the batch.',
                404,
            );
        }

        $enrollment->update([
            'left_at' => now(),
            'status' => ProfileStatus::Inactive,
        ]);

        return $enrollment->refresh();
    }
}
