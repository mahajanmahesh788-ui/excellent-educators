<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ClassAttendance extends Model
{
    use HasUlids;

    protected $fillable = [
        'booking_id',
        'student_id',
        'teacher_id',
        'student_first_join_at',
        'student_last_join_at',
        'student_join_count',
        'teacher_first_join_at',
        'teacher_last_join_at',
        'teacher_join_count',
        'teacher_whatsapp_reminder_sent_at',
        'rebooking_granted',
        'rebooking_granted_at',
        'replacement_booking_id',
    ];

    protected function casts(): array
    {
        return [
            'student_first_join_at' => 'datetime',
            'student_last_join_at' => 'datetime',
            'teacher_first_join_at' => 'datetime',
            'teacher_last_join_at' => 'datetime',
            'teacher_whatsapp_reminder_sent_at' => 'datetime',
            'rebooking_granted' => 'boolean',
            'rebooking_granted_at' => 'datetime',
        ];
    }

    public function booking(): BelongsTo
    {
        return $this->belongsTo(SessionBooking::class, 'booking_id');
    }

    public function issues(): HasMany
    {
        return $this->hasMany(AttendanceIssue::class, 'booking_id', 'booking_id');
    }

    public function hasUnusedRebooking(): bool
    {
        return $this->rebooking_granted && $this->replacement_booking_id === null;
    }
}
