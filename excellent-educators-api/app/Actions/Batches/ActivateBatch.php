<?php

namespace App\Actions\Batches;

use App\Actions\Learning\StartStudentLevelJourney;
use App\Enums\BatchStatus;
use App\Enums\ProfileStatus;
use App\Models\AcademicLevel;
use App\Models\Batch;
use App\Models\BatchStudent;
use App\Models\StudentProfile;
use App\Support\AppClock;
use App\Support\SyncUserAccess;
use Illuminate\Support\Facades\DB;

class ActivateBatch
{
    public function __construct(private readonly StartStudentLevelJourney $startStudentLevelJourney) {}

    public function execute(Batch $batch): Batch
    {
        return DB::transaction(function () use ($batch): Batch {
            $batch = Batch::query()->lockForUpdate()->findOrFail($batch->id);

            $alreadyActive = $batch->status === BatchStatus::Active
                || $batch->status === 'active';

            // Journey weeks follow batch activation day — not level go-live
            // and not a stale starts_on left from an earlier draft.
            if (! $alreadyActive) {
                $batch->update([
                    'status' => BatchStatus::Active,
                    'starts_on' => AppClock::todayString(),
                ]);
            } elseif ($batch->starts_on === null) {
                $batch->update(['starts_on' => AppClock::todayString()]);
            }

            $batch->refresh();

            $level = $batch->level ?? AcademicLevel::query()->find($batch->level_id);
            if ($level === null) {
                return $batch;
            }

            $startedAt = $batch->starts_on?->copy()->startOfDay() ?? AppClock::now();

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

                // Re-enable students paused when this batch was deactivated.
                if ($student->status !== ProfileStatus::Active) {
                    $student->update(['status' => ProfileStatus::Active]);
                }
                if ($student->user !== null) {
                    SyncUserAccess::syncFromProfileStatus(
                        $student->user,
                        ProfileStatus::Active->value,
                    );
                }

                $this->startStudentLevelJourney->execute($student, $level, $startedAt);
            }

            return $batch->fresh();
        });
    }
}
