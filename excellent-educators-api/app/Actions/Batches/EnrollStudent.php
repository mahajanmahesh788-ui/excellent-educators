<?php

namespace App\Actions\Batches;

use App\Actions\Learning\StartStudentLevelJourney;
use App\Actions\Notifications\DispatchAssignmentNotifications;
use App\Enums\ProfileStatus;
use App\Exceptions\ApiException;
use App\Models\AcademicLevel;
use App\Models\Batch;
use App\Models\BatchStudent;
use App\Models\StudentProfile;
use App\Models\User;
use App\Support\ErrorCode;
use Illuminate\Support\Facades\DB;

class EnrollStudent
{
    public function __construct(
        private readonly DispatchAssignmentNotifications $dispatchAssignmentNotifications,
        private readonly StartStudentLevelJourney $startStudentLevelJourney,
    ) {}

    public function execute(Batch $batch, StudentProfile $student, User $actor): BatchStudent
    {
        $enrollment = DB::transaction(function () use ($batch, $student, $actor): BatchStudent {
            $batch = Batch::query()->lockForUpdate()->findOrFail($batch->id);

            $maxActive = app(\App\Support\AppSettings::class)->maxActiveStudents();
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
                ->first();

            if ($activeElsewhere) {
                $activeElsewhere->update([
                    'left_at' => now(),
                    'status' => ProfileStatus::Inactive,
                ]);
            }

            $enrollment = BatchStudent::query()->create([
                'batch_id' => $batch->id,
                'student_id' => $student->id,
                'enrolled_by' => $actor->id,
                'status' => ProfileStatus::Active,
                'enrolled_at' => now(),
            ]);

            $batch->increment('enrolled_watermark');

            if ($batch->level_id && $student->level_id !== $batch->level_id) {
                $student->update(['level_id' => $batch->level_id]);
                $level = $batch->level ?? AcademicLevel::query()->find($batch->level_id);
                if ($level !== null) {
                    $this->startStudentLevelJourney->execute($student->fresh(), $level);
                }
            }

            return $enrollment;
        });

        $this->dispatchAssignmentNotifications->studentEnrolled($batch, $student);

        return $enrollment;
    }
}
