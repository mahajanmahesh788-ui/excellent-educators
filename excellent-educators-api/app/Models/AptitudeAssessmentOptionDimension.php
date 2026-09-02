<?php

namespace App\Models;

use App\Enums\DimensionCode;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AptitudeAssessmentOptionDimension extends Model
{
    use HasUlids;

    protected $fillable = [
        'aptitude_assessment_option_id',
        'dimension_code',
        'display_order',
    ];

    protected function casts(): array
    {
        return [
            'dimension_code' => DimensionCode::class,
            'display_order' => 'integer',
        ];
    }

    public function option(): BelongsTo
    {
        return $this->belongsTo(AptitudeAssessmentOption::class, 'aptitude_assessment_option_id');
    }
}
