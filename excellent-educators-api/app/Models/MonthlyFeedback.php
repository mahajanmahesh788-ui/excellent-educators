<?php

namespace App\Models;

use App\Support\AppClock;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class MonthlyFeedback extends Model
{
    use HasUlids;

    protected $table = 'monthly_feedbacks';

    protected $fillable = [
        'student_id',
        'master_teacher_id',
        'session_booking_id',
        'year',
        'month',
        'session_date',
        'positive_points',
        'areas_for_improvement',
        'discussed_in_class',
        'submitted_at',
    ];

    protected function casts(): array
    {
        return [
            'year' => 'integer',
            'month' => 'integer',
            'session_date' => 'date',
            'submitted_at' => 'datetime',
        ];
    }

    public function student(): BelongsTo
    {
        return $this->belongsTo(StudentProfile::class, 'student_id');
    }

    public function masterTeacher(): BelongsTo
    {
        return $this->belongsTo(TeacherProfile::class, 'master_teacher_id');
    }

    public function booking(): BelongsTo
    {
        return $this->belongsTo(SessionBooking::class, 'session_booking_id');
    }

    public function sessionAverage(): ?float
    {
        $ratings = $this->items->pluck('rating');
        if ($ratings->isEmpty()) {
            return null;
        }

        return round((float) $ratings->avg(), 1);
    }

    public function items(): HasMany
    {
        return $this->hasMany(MonthlyFeedbackItem::class);
    }

    public function isWithinRatingMonth(): bool
    {
        ['year' => $year, 'month' => $month] = AppClock::currentYearMonth();

        return $this->year === $year && $this->month === $month;
    }

    public function isEditable(): bool
    {
        return $this->isWithinRatingMonth();
    }

    public function isDeletable(): bool
    {
        return $this->isWithinRatingMonth();
    }
}
