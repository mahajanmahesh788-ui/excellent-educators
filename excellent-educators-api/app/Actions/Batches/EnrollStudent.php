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
use App\Support\StudentActivity;
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
            }

            $level = $batch->level ?? AcademicLevel::query()->find($batch->level_id);
            if ($level !== null) {
                $this->startStudentLevelJourney->executeIfBatchActive($student->fresh(), $level);
            }

            return $enrollment;
        });

        $fromBatch = BatchStudent::query()
            ->with('batch')
            ->where('student_id', $student->id)
            ->whereNotNull('left_at')
            ->orderByDesc('left_at')
            ->first();

        $message = $fromBatch?->batch
            ? "Moved from {$fromBatch->batch->name} to {$batch->name}."
            : "Enrolled in batch {$batch->name}.";

        StudentActivity::record(
            $student->fresh() ?? $student,
            $fromBatch ? 'batch_changed' : 'batch_enrolled',
            $message,
            $actor,
            $enrollment,
            [
                'batch_id' => $batch->id,
                'batch_name' => $batch->name,
                'previous_batch_id' => $fromBatch?->batch_id,
                'previous_batch_name' => $fromBatch?->batch?->name,
            ],
        );

        $this->dispatchAssignmentNotifications->studentEnrolled($batch, $student);

        return $enrollment;
    }
}
