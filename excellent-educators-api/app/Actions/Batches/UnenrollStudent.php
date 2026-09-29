<?php

namespace App\Actions\Batches;

use App\Actions\Notifications\DispatchAssignmentNotifications;
use App\Enums\ProfileStatus;
use App\Exceptions\ApiException;
use App\Models\Batch;
use App\Models\BatchStudent;
use App\Models\StudentProfile;
use App\Support\ErrorCode;
use App\Support\StudentActivity;

class UnenrollStudent
{
    public function __construct(
        private readonly DispatchAssignmentNotifications $dispatchAssignmentNotifications,
    ) {}

    public function execute(Batch $batch, StudentProfile $student, ?\App\Models\User $actor = null): BatchStudent
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

        $enrollment = $enrollment->refresh();

        StudentActivity::record(
            $student,
            'batch_unenrolled',
            "Removed from batch {$batch->name}.",
            $actor,
            $enrollment,
            ['batch_id' => $batch->id, 'batch_name' => $batch->name],
        );

        $this->dispatchAssignmentNotifications->studentUnenrolled($batch, $student);

        return $enrollment;
    }
}
