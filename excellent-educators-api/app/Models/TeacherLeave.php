<?php

namespace App\Models;

use App\Enums\TeacherLeaveStatus;
use App\Support\AppClock;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TeacherLeave extends Model
{
    use HasUlids;

    protected $fillable = [
        'request_group_id',
        'teacher_id',
        'date',
        'start_time',
        'end_time',
        'is_full_day',
        'reason',
        'status',
        'reviewed_by',
        'reviewed_at',
        'rejection_reason',
        'created_by',
    ];

    protected function casts(): array
    {
        return [
            'date' => 'date',
            'is_full_day' => 'boolean',
            'status' => TeacherLeaveStatus::class,
            'reviewed_at' => 'datetime',
        ];
    }

    public function teacher(): BelongsTo
    {
        return $this->belongsTo(TeacherProfile::class, 'teacher_id');
    }

    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function reviewedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reviewed_by');
    }

    public function dateHasPassed(): bool
    {
        $date = $this->date?->toDateString();

        return $date !== null && $date < AppClock::todayString();
    }

    /**
     * @return array<string, mixed>
     */
    public function toScheduleArray(): array
    {
        return [
            'id' => $this->id,
            'request_group_id' => $this->request_group_id,
            'teacher_id' => $this->teacher_id,
            'teacher_name' => $this->relationLoaded('teacher') ? $this->teacher?->full_name : null,
            'date' => $this->date?->toDateString(),
            'start_time' => substr((string) $this->start_time, 0, 5),
            'end_time' => substr((string) $this->end_time, 0, 5),
            'is_full_day' => $this->is_full_day,
            'reason' => $this->reason,
            'status' => $this->status?->value ?? TeacherLeaveStatus::Approved->value,
            'rejection_reason' => $this->rejection_reason,
            'reviewed_at' => $this->reviewed_at?->toIso8601String(),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
