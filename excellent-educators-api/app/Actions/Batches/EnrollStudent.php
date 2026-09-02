<?php

namespace App\Actions\Batches;

use App\Enums\ProfileStatus;
use App\Exceptions\ApiException;
use App\Models\Batch;
use App\Models\BatchStudent;
use App\Models\StudentProfile;
use App\Models\User;
use App\Support\ErrorCode;
use Illuminate\Support\Facades\DB;

class EnrollStudent
{
    public function execute(Batch $batch, StudentProfile $student, User $actor): BatchStudent
    {
        if ($student->career_compass_level_id !== $batch->career_compass_level_id) {
            throw new ApiException(
                ErrorCode::VALIDATION_ERROR,
                'Student Career Compass level must match the batch.',
                422,
            );
        }

        return DB::transaction(function () use ($batch, $student, $actor): BatchStudent {
            $batch = Batch::query()->lockForUpdate()->findOrFail($batch->id);

            $maxActive = (int) config('excellent_educators.batch.max_active_students', 40);
            $activeCount = BatchStudent::query()
                ->where('batch_id', $batch->id)
                ->whereNull('left_at')
                ->where('status', ProfileStatus::Active->value)
                ->count();

            if ($activeCount >= $maxActive) {
                throw new ApiException(
                    ErrorCode::BATCH_FULL,
                    "This batch has reached the maximum limit of {$maxActive} active students.",
                    409,
                );
            }

            $alreadyInThisBatch = BatchStudent::query()
                ->where('batch_id', $batch->id)
                ->where('student_id', $student->id)
                ->whereNull('left_at')
                ->where('status', ProfileStatus::Active->value)
                ->exists();

            if ($alreadyInThisBatch) {
                throw new ApiException(
                    ErrorCode::CONFLICT,
                    'This student is already active in this batch.',
                    409,
                );
            }

            $activeElsewhere = BatchStudent::query()
                ->where('student_id', $student->id)
                ->whereNull('left_at')
                ->where('status', ProfileStatus::Active->value)
                ->exists();

            if ($activeElsewhere) {
                throw new ApiException(
                    ErrorCode::CONFLICT,
                    'This student is already active in another batch.',
                    409,
                );
            }

            return BatchStudent::query()->create([
                'batch_id' => $batch->id,
                'student_id' => $student->id,
                'enrolled_by' => $actor->id,
                'status' => ProfileStatus::Active,
                'enrolled_at' => now(),
            ]);
        });
    }
}
