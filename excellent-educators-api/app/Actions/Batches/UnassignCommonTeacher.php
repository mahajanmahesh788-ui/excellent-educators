<?php

namespace App\Actions\Batches;

use App\Models\Batch;
use App\Models\BatchTeacher;
use Illuminate\Support\Facades\DB;

class UnassignCommonTeacher
{
    public function execute(Batch $batch): void
    {
        DB::transaction(function () use ($batch): void {
            $current = BatchTeacher::query()
                ->where('batch_id', $batch->id)
                ->whereNull('ended_at')
                ->lockForUpdate()
                ->first();

            if ($current) {
                $current->update(['ended_at' => now()]);
            }
        });
    }
}
