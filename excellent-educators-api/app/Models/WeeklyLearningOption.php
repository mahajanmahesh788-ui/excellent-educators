<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class WeeklyLearningOption extends Model
{
    use HasUlids;

    protected $fillable = [
        'question_id',
        'option_text',
        'display_order',
        'is_correct',
    ];

    protected function casts(): array
    {
        return [
            'display_order' => 'integer',
            'is_correct' => 'boolean',
        ];
    }

    public function question(): BelongsTo
    {
        return $this->belongsTo(WeeklyLearningQuestion::class, 'question_id');
    }
}
