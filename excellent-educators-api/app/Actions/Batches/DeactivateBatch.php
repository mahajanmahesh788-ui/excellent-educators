<?php

namespace App\Actions\Batches;

use App\Actions\Learning\StartStudentLevelJourney;
use App\Enums\BatchStatus;
use App\Enums\ProfileStatus;
use App\Models\Batch;
use App\Models\BatchStudent;
use App\Models\StudentProfile;
use App\Support\AppClock;
use App\Support\SyncUserAccess;
use Illuminate\Support\Facades\DB;

/**
 * Pause a live batch: mark inactive, end open journeys, and revoke student
 * portal access until the batch is activated again.
 */
class DeactivateBatch
{
    public function __construct(
        private readonly StartStudentLevelJourney $startStudentLevelJourney,
    ) {}

    public function execute(Batch $batch): Batch
    {
        return DB::transaction(function () use ($batch): Batch {
            $batch = Batch::query()->lockForUpdate()->findOrFail($batch->id);

            $isActive = $batch->status === BatchStatus::Active
                || $batch->status === 'active';

            if (! $isActive) {
                return $batch;
            }

            $batch->update(['status' => BatchStatus::Inactive]);
            $endedAt = AppClock::now();

            $studentIds = BatchStudent::query()
                ->where('batch_id', $batch->id)
                ->whereNull('left_at')
                ->where('status', ProfileStatus::Active->value)
                ->pluck('student_id');

            foreach ($studentIds as $studentId) {
                $student = StudentProfile::query()->with('user')->find($studentId);
                if ($student === null) {
                    continue;
                }

                $this->startStudentLevelJourney->endOpenJourneys($student, $endedAt);

                if ($student->status !== ProfileStatus::Inactive) {
                    $student->update(['status' => ProfileStatus::Inactive]);
                }

                if ($student->user !== null) {
                    SyncUserAccess::syncFromProfileStatus(
                        $student->user,
                        ProfileStatus::Inactive->value,
                    );
                }
            }

            return $batch->fresh();
        });
    }
}
