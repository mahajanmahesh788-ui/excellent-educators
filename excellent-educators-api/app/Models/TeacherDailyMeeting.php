<?php

namespace App\Models;

use App\Enums\TeacherDailyMeetingStatus;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TeacherDailyMeeting extends Model
{
    use HasUlids;

    protected $fillable = [
        'teacher_id',
        'date',
        'google_event_id',
        'google_meeting_space_id',
        'meet_url',
        'status',
        'first_join_at',
        'last_join_at',
        'join_count',
    ];

    protected function casts(): array
    {
        return [
            'date' => 'date',
            'status' => TeacherDailyMeetingStatus::class,
            'first_join_at' => 'datetime',
            'last_join_at' => 'datetime',
        ];
    }

    public function teacher(): BelongsTo
    {
        return $this->belongsTo(TeacherProfile::class, 'teacher_id');
    }

    public function isReady(): bool
    {
        return $this->status === TeacherDailyMeetingStatus::Ready
            && filled($this->meet_url);
    }
}
