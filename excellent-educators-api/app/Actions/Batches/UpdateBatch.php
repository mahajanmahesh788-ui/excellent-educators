<?php

namespace App\Actions\Batches;

use App\Models\Batch;

class UpdateBatch
{
    /**
     * @param  array<string, mixed>  $input
     */
    public function execute(Batch $batch, array $input): Batch
    {
        $batch->fill([
            'name' => $input['name'] ?? $batch->name,
            'academic_year' => $input['academic_year'] ?? $batch->academic_year,
            'starts_on' => array_key_exists('starts_on', $input) ? $input['starts_on'] : $batch->starts_on,
            'ends_on' => array_key_exists('ends_on', $input) ? $input['ends_on'] : $batch->ends_on,
            'status' => $input['status'] ?? $batch->status,
        ]);
        $batch->save();

        return $batch->refresh();
    }
}
