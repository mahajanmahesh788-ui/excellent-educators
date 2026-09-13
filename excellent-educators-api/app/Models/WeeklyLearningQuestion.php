<?php

namespace App\Models;

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
        'display_order',
    ];

    protected function casts(): array
    {
        return [
            'display_order' => 'integer',
        ];
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
