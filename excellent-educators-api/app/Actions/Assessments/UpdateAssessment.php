<?php

namespace App\Actions\Assessments;

use App\Enums\AssessmentStatus;
use App\Models\Assessment;
use App\Models\AssessmentScore;
use App\Models\AssessmentVersion;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class UpdateAssessment
{
    /**
     * @param  array<string, mixed>  $input
     */
    public function execute(Assessment $assessment, User $actor, array $input): Assessment
    {
        return DB::transaction(function () use ($assessment, $actor, $input): Assessment {
            $nextTitle = $input['title'] ?? $assessment->title;
            $nextDescription = array_key_exists('description', $input) ? $input['description'] : $assessment->description;
            $nextMaxScore = $input['max_score'] ?? $assessment->max_score;
            $nextStatus = $input['status'] ?? $assessment->status?->value ?? $assessment->status;

            $hasCurrentScores = AssessmentScore::query()
                ->where('assessment_id', $assessment->id)
                ->where('version', $assessment->version)
                ->whereNotNull('score')
                ->exists();

            $definitionChanged = $nextTitle !== $assessment->title
                || $nextDescription !== $assessment->description
                || (string) $nextMaxScore !== (string) $assessment->max_score;

            if ($hasCurrentScores && $definitionChanged) {
                AssessmentVersion::query()->create([
                    'assessment_id' => $assessment->id,
                    'version' => $assessment->version,
                    'title' => $assessment->title,
                    'description' => $assessment->description,
                    'max_score' => $assessment->max_score,
                    'revised_by' => $actor->id,
                    'created_at' => now(),
                ]);
                $assessment->version++;
            }

            $assessment->fill([
                'title' => $nextTitle,
                'description' => $nextDescription,
                'max_score' => $nextMaxScore,
                'status' => $nextStatus,
            ]);
            $assessment->save();

            return $assessment->refresh();
        });
    }

    public function publish(Assessment $assessment): Assessment
    {
        $assessment->update(['status' => AssessmentStatus::Published]);

        return $assessment->refresh();
    }
}
