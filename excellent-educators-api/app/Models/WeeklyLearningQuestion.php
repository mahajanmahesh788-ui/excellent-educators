<?php

namespace App\Models;

use App\Enums\WeeklyQuestionType;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class WeeklyLearningQuestion extends Model
{
    use HasUlids;

    protected $fillable = [
        'weekly_learning_id',
        'question_text',
        'question_type',
        'display_order',
    ];

    protected function casts(): array
    {
        return [
            'question_type' => WeeklyQuestionType::class,
            'display_order' => 'integer',
        ];
    }

    public function isText(): bool
    {
        return $this->question_type === WeeklyQuestionType::Text;
    }

    public function isOptions(): bool
    {
        return $this->question_type === WeeklyQuestionType::Options;
    }

    public function weeklyLearning(): BelongsTo
    {
        return $this->belongsTo(WeeklyLearning::class);
    }

    public function options(): HasMany
    {
        return $this->hasMany(WeeklyLearningOption::class, 'question_id')->orderBy('display_order');
    }
}
