<?php

namespace App\Models;

use App\Enums\SessionBookingStatus;
use App\Enums\SessionBookingType;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class SessionBooking extends Model
{
    use HasUlids;

    protected $fillable = [
        'student_id',
        'teacher_id',
        'reassigned_from_teacher_id',
        'reassigned_at',
        'type',
        'date',
        'starts_at',
        'ends_at',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'type' => SessionBookingType::class,
            'status' => SessionBookingStatus::class,
            'date' => 'date',
            'starts_at' => 'datetime',
            'ends_at' => 'datetime',
            'reassigned_at' => 'datetime',
        ];
    }

    public function student(): BelongsTo
    {
        return $this->belongsTo(StudentProfile::class, 'student_id');
    }

    public function teacher(): BelongsTo
    {
        return $this->belongsTo(TeacherProfile::class, 'teacher_id');
    }

    public function reassignedFromTeacher(): BelongsTo
    {
        return $this->belongsTo(TeacherProfile::class, 'reassigned_from_teacher_id');
    }

    public function attendanceIssues(): HasMany
    {
        return $this->hasMany(AttendanceIssue::class, 'booking_id');
    }

    public function monthlyFeedback(): HasOne
    {
        return $this->hasOne(MonthlyFeedback::class, 'session_booking_id');
    }

    public function scopeActive(Builder $query): Builder
    {
        return $query->whereIn('status', [
            SessionBookingStatus::Scheduled->value,
            SessionBookingStatus::Completed->value,
        ]);
    }

    public function scopeBlocking(Builder $query): Builder
    {
        return $query->where('status', '!=', SessionBookingStatus::Cancelled->value);
    }
}
