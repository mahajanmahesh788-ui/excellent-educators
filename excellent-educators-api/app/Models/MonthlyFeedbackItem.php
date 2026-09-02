<?php

namespace App\Models;

use App\Enums\FeedbackTargetType;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphTo;

class MonthlyFeedbackItem extends Model
{
    use HasUlids;

    protected $fillable = [
        'monthly_feedback_id',
        'target_type',
        'target_id',
        'rating',
        'positive_points',
        'areas_for_improvement',
        'recommended_next_action',
    ];

    protected function casts(): array
    {
        return [
            'target_type' => FeedbackTargetType::class,
            'rating' => 'integer',
        ];
    }

    public function feedback(): BelongsTo
    {
        return $this->belongsTo(MonthlyFeedback::class, 'monthly_feedback_id');
    }

    public function target(): MorphTo
    {
        return $this->morphTo(__FUNCTION__, 'target_type', 'target_id');
    }

    public function resolveTargetName(): string
    {
        return match ($this->target_type) {
            FeedbackTargetType::Dimension => Dimension::query()->find($this->target_id)?->name ?? 'Unknown dimension',
            FeedbackTargetType::Module => DevelopmentModule::query()->find($this->target_id)?->name ?? 'Unknown module',
            FeedbackTargetType::Skill => Skill::query()->find($this->target_id)?->name ?? 'Unknown skill',
            default => 'Unknown',
        };
    }
}
