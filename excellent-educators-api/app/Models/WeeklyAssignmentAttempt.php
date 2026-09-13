<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class WeeklyAssignmentAttempt extends Model
{
    use HasUlids;

    protected $fillable = [
        'student_id',
        'student_level_journey_id',
        'weekly_learning_id',
        'week_number',
        'attempt_number',
        'answers',
        'video_url',
        'submitted_at',
    ];

    protected function casts(): array
    {
        return [
            'week_number' => 'integer',
            'attempt_number' => 'integer',
            'answers' => 'array',
            'submitted_at' => 'datetime',
        ];
    }

    public function student(): BelongsTo
    {
        return $this->belongsTo(StudentProfile::class, 'student_id');
    }

    public function journey(): BelongsTo
    {
        return $this->belongsTo(StudentLevelJourney::class, 'student_level_journey_id');
    }

    public function weeklyLearning(): BelongsTo
    {
        return $this->belongsTo(WeeklyLearning::class);
    }
}
