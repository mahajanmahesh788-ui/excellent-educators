<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class AptitudeAssessmentOption extends Model
{
    use HasUlids;

    protected $fillable = [
        'aptitude_assessment_question_id',
        'option_text',
        'display_order',
    ];

    protected function casts(): array
    {
        return [
            'display_order' => 'integer',
        ];
    }

    public function question(): BelongsTo
    {
        return $this->belongsTo(AptitudeAssessmentQuestion::class, 'aptitude_assessment_question_id');
    }

    public function dimensionCodes(): HasMany
    {
        return $this->hasMany(AptitudeAssessmentOptionDimension::class, 'aptitude_assessment_option_id')
            ->orderBy('display_order');
    }

    public function hasValidDimensionCodes(): bool
    {
        $count = $this->relationLoaded('dimensionCodes')
            ? $this->dimensionCodes->count()
            : $this->dimensionCodes()->count();

        return $count >= 1 && $count <= 3;
    }
}
