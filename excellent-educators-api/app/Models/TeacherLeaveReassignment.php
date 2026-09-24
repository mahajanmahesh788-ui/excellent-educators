<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TeacherLeaveReassignment extends Model
{
    use HasUlids;

    protected $fillable = [
        'leave_request_group_id',
        'booking_id',
        'replacement_teacher_id',
        'assigned_by',
        'assigned_at',
    ];

    protected function casts(): array
    {
        return [
            'assigned_at' => 'datetime',
        ];
    }

    public function booking(): BelongsTo
    {
        return $this->belongsTo(SessionBooking::class, 'booking_id');
    }

    public function replacementTeacher(): BelongsTo
    {
        return $this->belongsTo(TeacherProfile::class, 'replacement_teacher_id');
    }

    public function assignedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'assigned_by');
    }

    public function isAssigned(): bool
    {
        return $this->replacement_teacher_id !== null;
    }
}
