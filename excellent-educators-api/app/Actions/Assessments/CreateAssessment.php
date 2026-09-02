<?php

namespace App\Actions\Assessments;

use App\Enums\AssessmentStatus;
use App\Models\Assessment;
use App\Models\Batch;
use App\Models\User;

class CreateAssessment
{
    /**
     * @param  array{
     *     title: string,
     *     description?: string|null,
     *     max_score: float|int|string,
     *     status?: string
     * }  $input
     */
    public function execute(Batch $batch, User $actor, array $input): Assessment
    {
        return Assessment::query()->create([
            'batch_id' => $batch->id,
            'created_by' => $actor->id,
            'title' => $input['title'],
            'description' => $input['description'] ?? null,
            'max_score' => $input['max_score'],
            'version' => 1,
            'status' => $input['status'] ?? AssessmentStatus::Draft,
        ]);
    }
}
