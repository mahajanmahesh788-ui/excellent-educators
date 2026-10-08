<?php

namespace App\Models;

use App\Enums\WeeklyQuestionSection;
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
        'section',
        'display_order',
    ];

    protected function casts(): array
    {
        return [
            'question_type' => WeeklyQuestionType::class,
            'section' => WeeklyQuestionSection::class,
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

    public function isComprehension(): bool
    {
        return $this->section === WeeklyQuestionSection::Comprehension;
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
