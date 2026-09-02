<?php

namespace App\Models;

use App\Enums\DimensionCode;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AptitudeAssessmentResultDimension extends Model
{
    use HasUlids;

    protected $fillable = [
        'aptitude_assessment_result_id',
        'dimension_code',
        'score',
    ];

    protected function casts(): array
    {
        return [
            'dimension_code' => DimensionCode::class,
            'score' => 'integer',
        ];
    }

    public function result(): BelongsTo
    {
        return $this->belongsTo(AptitudeAssessmentResult::class, 'aptitude_assessment_result_id');
    }
}
