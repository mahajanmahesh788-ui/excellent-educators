<?php

namespace App\Models;

use App\Enums\AssessmentAttemptStatus;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class AptitudeAssessmentAttempt extends Model
{
    use HasUlids;

    protected $fillable = [
        'aptitude_assessment_id',
        'student_id',
        'started_at',
        'submitted_at',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'started_at' => 'datetime',
            'submitted_at' => 'datetime',
            'status' => AssessmentAttemptStatus::class,
        ];
    }

    public function assessment(): BelongsTo
    {
        return $this->belongsTo(AptitudeAssessment::class, 'aptitude_assessment_id');
    }

    public function student(): BelongsTo
    {
        return $this->belongsTo(StudentProfile::class, 'student_id');
    }

    public function answers(): HasMany
    {
        return $this->hasMany(AptitudeAssessmentAnswer::class);
    }

    public function result(): HasOne
    {
        return $this->hasOne(AptitudeAssessmentResult::class);
    }

    public function isSubmitted(): bool
    {
        return $this->status === AssessmentAttemptStatus::Submitted;
    }
}
