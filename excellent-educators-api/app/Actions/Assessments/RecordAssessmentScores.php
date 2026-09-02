<?php

namespace App\Actions\Assessments;

use App\Exceptions\ApiException;
use App\Models\Assessment;
use App\Models\AssessmentScore;
use App\Models\Batch;
use App\Models\User;
use App\Support\ErrorCode;
use Illuminate\Support\Facades\DB;

class RecordAssessmentScores
{
    /**
     * @param  list<array{student_id: string, score?: float|int|string|null, notes?: string|null}>  $entries
     */
    public function execute(Assessment $assessment, Batch $batch, User $actor, array $entries): Assessment
    {
        $activeStudentIds = $batch->activeEnrollments()->pluck('student_id')->all();

        return DB::transaction(function () use ($assessment, $actor, $entries, $activeStudentIds): Assessment {
            foreach ($entries as $entry) {
                $studentId = $entry['student_id'];
                if (! in_array($studentId, $activeStudentIds, true)) {
                    throw new ApiException(
                        ErrorCode::VALIDATION_ERROR,
                        'One or more students are not active in this batch.',
                        422,
                    );
                }

                $scoreValue = array_key_exists('score', $entry) ? $entry['score'] : null;
                if ($scoreValue !== null && $scoreValue > $assessment->max_score) {
                    throw new ApiException(
                        ErrorCode::VALIDATION_ERROR,
                        "Score cannot exceed max score of {$assessment->max_score}.",
                        422,
                    );
                }

                $record = AssessmentScore::query()->firstOrNew([
                    'assessment_id' => $assessment->id,
                    'student_id' => $studentId,
                    'version' => $assessment->version,
                ]);

                $record->fill([
                    'score' => $scoreValue,
                    'notes' => array_key_exists('notes', $entry) ? $entry['notes'] : $record->notes,
                    'scored_by' => $scoreValue === null ? null : $actor->id,
                    'scored_at' => $scoreValue === null ? null : now(),
                ]);
                $record->save();
            }

            return $assessment->refresh();
        });
    }
}
