<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Carbon;

class StudentLevelJourney extends Model
{
    use HasUlids;

    protected $fillable = [
        'student_id',
        'level_id',
        'started_at',
        'ended_at',
    ];

    protected function casts(): array
    {
        return [
            'started_at' => 'datetime',
            'ended_at' => 'datetime',
        ];
    }

    public function student(): BelongsTo
    {
        return $this->belongsTo(StudentProfile::class, 'student_id');
    }

    public function level(): BelongsTo
    {
        return $this->belongsTo(AcademicLevel::class, 'level_id');
    }

    public function attempts(): HasMany
    {
        return $this->hasMany(WeeklyAssignmentAttempt::class);
    }

    public function isCurrent(): bool
    {
        return $this->ended_at === null;
    }

    public function weekNumberAt(?Carbon $asOf = null): int
    {
        $end = $this->ended_at ?? $asOf ?? now();
        $start = $this->started_at->copy()->startOfDay();
        $days = max(0, $start->diffInDays($end->copy()->startOfDay()));

        return min(52, 1 + intdiv($days, 7));
    }

    /**
     * Calendar months since journey start (1 = activation month).
     */
    public function monthNumberAt(?Carbon $asOf = null): int
    {
        $at = ($asOf ?? now())->copy()->startOfMonth();
        $start = $this->started_at->copy()->startOfMonth();

        return max(1, ((int) $start->diffInMonths($at)) + 1);
    }
}
