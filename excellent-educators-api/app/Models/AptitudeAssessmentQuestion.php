<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class AptitudeAssessmentQuestion extends Model
{
    use HasUlids;

    protected $fillable = [
        'aptitude_assessment_id',
        'question_text',
        'display_order',
    ];

    protected function casts(): array
    {
        return [
            'display_order' => 'integer',
        ];
    }

    public function assessment(): BelongsTo
    {
        return $this->belongsTo(AptitudeAssessment::class, 'aptitude_assessment_id');
    }

    public function options(): HasMany
    {
        return $this->hasMany(AptitudeAssessmentOption::class)->orderBy('display_order');
    }
}
