<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class WeeklyLearning extends Model
{
    use HasUlids;

    protected $fillable = [
        'level_id',
        'week_number',
        'video_url',
    ];

    protected function casts(): array
    {
        return [
            'week_number' => 'integer',
        ];
    }

    public function level(): BelongsTo
    {
        return $this->belongsTo(AcademicLevel::class, 'level_id');
    }

    public function questions(): HasMany
    {
        return $this->hasMany(WeeklyLearningQuestion::class)->orderBy('display_order');
    }

    public function attempts(): HasMany
    {
        return $this->hasMany(WeeklyAssignmentAttempt::class);
    }
}
