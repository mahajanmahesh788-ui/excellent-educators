<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AptitudeAssessmentAnswer extends Model
{
    use HasUlids;

    protected $fillable = [
        'aptitude_assessment_attempt_id',
        'aptitude_assessment_question_id',
        'aptitude_assessment_option_id',
    ];

    public function attempt(): BelongsTo
    {
        return $this->belongsTo(AptitudeAssessmentAttempt::class, 'aptitude_assessment_attempt_id');
    }

    public function question(): BelongsTo
    {
        return $this->belongsTo(AptitudeAssessmentQuestion::class, 'aptitude_assessment_question_id');
    }

    public function option(): BelongsTo
    {
        return $this->belongsTo(AptitudeAssessmentOption::class, 'aptitude_assessment_option_id');
    }
}
