<?php

namespace App\Actions\Batches;

use App\Enums\BatchStatus;
use App\Models\Batch;

class UpdateBatch
{
    public function __construct(private readonly ActivateBatch $activateBatch) {}

    /**
     * @param  array<string, mixed>  $input
     */
    public function execute(Batch $batch, array $input): Batch
    {
        $nextStatus = $input['status'] ?? null;
        $becomingActive = $nextStatus === BatchStatus::Active->value
            || $nextStatus === BatchStatus::Active
            || $nextStatus === 'active';

        $wasActive = $batch->status === BatchStatus::Active || $batch->status === 'active';

        if ($becomingActive && ! $wasActive) {
            $batch->fill([
                'name' => $input['name'] ?? $batch->name,
                'academic_year' => $input['academic_year'] ?? $batch->academic_year,
                'year' => $input['year'] ?? ($input['academic_year'] ?? $batch->year),
                'month' => $input['month'] ?? $batch->month,
                'starts_on' => array_key_exists('starts_on', $input) ? $input['starts_on'] : $batch->starts_on,
                'ends_on' => array_key_exists('ends_on', $input) ? $input['ends_on'] : $batch->ends_on,
            ]);
            $batch->save();

            return $this->activateBatch->execute($batch);
        }

        $batch->fill([
            'name' => $input['name'] ?? $batch->name,
            'academic_year' => $input['academic_year'] ?? $batch->academic_year,
            'year' => $input['year'] ?? ($input['academic_year'] ?? $batch->year),
            'month' => $input['month'] ?? $batch->month,
            'starts_on' => array_key_exists('starts_on', $input) ? $input['starts_on'] : $batch->starts_on,
            'ends_on' => array_key_exists('ends_on', $input) ? $input['ends_on'] : $batch->ends_on,
            'status' => $input['status'] ?? $batch->status,
        ]);
        $batch->save();

        return $batch->refresh();
    }
}
