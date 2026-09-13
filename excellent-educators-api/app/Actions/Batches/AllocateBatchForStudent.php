<?php

namespace App\Actions\Batches;

use App\Enums\ProfileStatus;
use App\Models\AcademicLevel;
use App\Models\Batch;
use App\Models\BatchStudent;
use App\Models\StudentProfile;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class AllocateBatchForStudent
{
    public function execute(AcademicLevel $level, StudentProfile $student, User $actor): Batch
    {
        return DB::transaction(function () use ($level, $student, $actor) {
            // Find currently active batch with watermark < 50
            $batch = Batch::query()
                ->where('level_id', $level->id)
                ->where('status', 'active')
                ->where('enrolled_watermark', '<', 50)
                ->orderBy('created_at')
                ->lockForUpdate()
                ->first();

            if (! $batch) {
                $count = Batch::query()->where('level_id', $level->id)->count();
                $batchNumber = $count + 1;
                $batchName = "Batch {$batchNumber}";

                // Ensure unique name within the level
                while (Batch::query()->where('level_id', $level->id)->where('name', $batchName)->exists()) {
                    $batchNumber++;
                    $batchName = "Batch {$batchNumber}";
                }

                $currentYear = (int) date('Y');
                $currentMonth = (int) date('n');

                $batch = Batch::query()->create([
                    'level_id' => $level->id,
                    'name' => $batchName,
                    'academic_year' => $level->academic_year ?? $currentYear,
                    'year' => $currentYear,
                    'month' => $currentMonth,
                    'status' => 'active',
                    'enrolled_watermark' => 0,
                ]);
            }

            // Verify not already active in this batch
            $alreadyActive = BatchStudent::query()
                ->where('batch_id', $batch->id)
                ->where('student_id', $student->id)
                ->whereNull('left_at')
                ->where('status', ProfileStatus::Active->value)
                ->exists();

            if (! $alreadyActive) {
                // If active in another batch, leave it
                BatchStudent::query()
                    ->where('student_id', $student->id)
                    ->whereNull('left_at')
                    ->where('status', ProfileStatus::Active->value)
                    ->update([
                        'left_at' => now(),
                        'status' => ProfileStatus::Inactive->value,
                    ]);

                BatchStudent::query()->create([
                    'batch_id' => $batch->id,
                    'student_id' => $student->id,
                    'enrolled_by' => $actor->id,
                    'status' => ProfileStatus::Active,
                    'enrolled_at' => now(),
                ]);

                $batch->increment('enrolled_watermark');
            }

            return $batch;
        });
    }
}
