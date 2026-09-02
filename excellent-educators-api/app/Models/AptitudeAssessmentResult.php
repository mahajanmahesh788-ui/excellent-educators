<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class AptitudeAssessmentResult extends Model
{
    use HasUlids;

    protected $fillable = [
        'aptitude_assessment_attempt_id',
        'student_id',
        'calculated_at',
    ];

    protected function casts(): array
    {
        return [
            'calculated_at' => 'datetime',
        ];
    }

    public function attempt(): BelongsTo
    {
        return $this->belongsTo(AptitudeAssessmentAttempt::class, 'aptitude_assessment_attempt_id');
    }

    public function student(): BelongsTo
    {
        return $this->belongsTo(StudentProfile::class, 'student_id');
    }

    public function dimensions(): HasMany
    {
        return $this->hasMany(AptitudeAssessmentResultDimension::class);
    }
}
