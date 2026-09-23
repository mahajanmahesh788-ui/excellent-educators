<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class WeeklyLearningOption extends Model
{
    use HasUlids;

    protected $fillable = [
        'question_id',
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
        return $this->belongsTo(WeeklyLearningQuestion::class, 'question_id');
    }

    public function dimensionCodes(): HasMany
    {
        return $this->hasMany(WeeklyLearningOptionDimension::class, 'weekly_learning_option_id')
            ->orderBy('display_order');
    }
}
