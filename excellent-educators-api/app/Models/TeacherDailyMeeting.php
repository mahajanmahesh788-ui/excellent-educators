<?php

namespace App\Models;

use App\Enums\TeacherDailyMeetingStatus;
use App\Support\AppClock;
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
        'google_meet_url',
        'meet_url_source',
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

    public function isManual(): bool
    {
        return ($this->meet_url_source ?? '') === 'manual' && filled($this->meet_url);
    }

    /** Manual day links are only valid on their calendar day. */
    public function manualLinkIsActive(): bool
    {
        if (! $this->isManual()) {
            return false;
        }

        $date = $this->date?->timezone(config('app.timezone'))->toDateString();

        return $date !== null && $date === AppClock::todayString();
    }

    public function manualLinkIsExpired(): bool
    {
        return $this->isManual() && ! $this->manualLinkIsActive();
    }
}
