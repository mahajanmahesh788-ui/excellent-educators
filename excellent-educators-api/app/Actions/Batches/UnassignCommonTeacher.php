<?php

namespace App\Actions\Batches;

use App\Actions\Notifications\DispatchAssignmentNotifications;
use App\Models\Batch;
use App\Models\BatchTeacher;
use Illuminate\Support\Facades\DB;

class UnassignCommonTeacher
{
    public function __construct(
        private readonly DispatchAssignmentNotifications $dispatchAssignmentNotifications,
    ) {}

    public function execute(Batch $batch): void
    {
        $previousTeacher = null;

        DB::transaction(function () use ($batch, &$previousTeacher): void {
            $current = BatchTeacher::query()
                ->where('batch_id', $batch->id)
                ->whereNull('ended_at')
                ->with('teacher')
                ->lockForUpdate()
                ->first();

            if ($current) {
                $previousTeacher = $current->teacher;
                $current->update(['ended_at' => now()]);
            }
        });

        if ($previousTeacher !== null) {
            $this->dispatchAssignmentNotifications->commonTeacherRemoved($batch, $previousTeacher);
        }
    }
}
