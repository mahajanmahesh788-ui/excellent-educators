<?php

namespace App\Actions\Batches;

use App\Enums\BatchStatus;
use App\Models\Batch;

class CreateBatch
{
    /**
     * @param  array{
     *     level_id?: string|null,
     *     name: string,
     *     academic_year: int,
     *     starts_on?: string|null,
     *     ends_on?: string|null
     * }  $input
     */
    public function execute(array $input): Batch
    {
        return Batch::query()->create([
            'level_id' => $input['level_id'] ?? null,
            'name' => $input['name'],
            'academic_year' => $input['academic_year'],
            'starts_on' => $input['starts_on'] ?? null,
            'ends_on' => $input['ends_on'] ?? null,
            'status' => BatchStatus::Active,
        ]);
    }
}
