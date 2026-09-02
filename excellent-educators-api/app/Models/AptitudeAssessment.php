<?php

namespace App\Models;

use App\Enums\AptitudeAssessmentStatus;
use App\Enums\AssessmentAttemptStatus;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class AptitudeAssessment extends Model
{
    use HasUlids, SoftDeletes;

    protected $fillable = [
        'career_compass_level_id',
        'title',
        'description',
        'status',
        'created_by',
        'updated_by',
    ];

    protected function casts(): array
    {
        return [
            'status' => AptitudeAssessmentStatus::class,
        ];
    }

    public function careerCompassLevel(): BelongsTo
    {
        return $this->belongsTo(CareerCompassLevel::class);
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function updater(): BelongsTo
    {
        return $this->belongsTo(User::class, 'updated_by');
    }

    public function questions(): HasMany
    {
        return $this->hasMany(AptitudeAssessmentQuestion::class)->orderBy('display_order');
    }

    public function attempts(): HasMany
    {
        return $this->hasMany(AptitudeAssessmentAttempt::class);
    }

    public function submittedAttempts(): HasMany
    {
        return $this->hasMany(AptitudeAssessmentAttempt::class)
            ->where('status', AssessmentAttemptStatus::Submitted->value);
    }

    public function isActive(): bool
    {
        return $this->status === AptitudeAssessmentStatus::Active;
    }

    public function hasSubmittedAttempts(): bool
    {
        return $this->submittedAttempts()->exists();
    }

    public function isComplete(): bool
    {
        if ($this->questions->isEmpty()) {
            return false;
        }

        foreach ($this->questions as $question) {
            if ($question->options->isEmpty()) {
                return false;
            }

            foreach ($question->options as $option) {
                if (! $option->hasValidDimensionCodes()) {
                    return false;
                }
            }
        }

        return true;
    }
}
