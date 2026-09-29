<?php

namespace App\Meetings;

use App\Enums\TeacherDailyMeetingStatus;
use App\Exceptions\ApiException;
use App\Models\TeacherDailyMeeting;
use App\Models\TeacherProfile;
use App\Support\ErrorCode;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Support\Facades\DB;

class TeacherDailyMeetingService
{
    public function __construct(
        private readonly GoogleMeetGateway $googleMeet,
    ) {}

    public function getOrCreate(TeacherProfile $teacher, string $date): TeacherDailyMeeting
    {
        return DB::transaction(function () use ($teacher, $date): TeacherDailyMeeting {
            $existing = TeacherDailyMeeting::query()
                ->where('teacher_id', $teacher->id)
                ->whereDate('date', $date)
                ->lockForUpdate()
                ->first();

            if ($existing?->isReady()) {
                return $existing;
            }

            if ($existing === null) {
                try {
                    $existing = TeacherDailyMeeting::query()->create([
                        'teacher_id' => $teacher->id,
                        'date' => $date,
                        'status' => TeacherDailyMeetingStatus::Pending->value,
                    ]);
                } catch (UniqueConstraintViolationException) {
                    $existing = TeacherDailyMeeting::query()
                        ->where('teacher_id', $teacher->id)
                        ->whereDate('date', $date)
                        ->lockForUpdate()
                        ->firstOrFail();
                    if ($existing->isReady()) {
                        return $existing;
                    }
                }
            }

            if ($existing->isReady()) {
                return $existing;
            }

            $created = $this->googleMeet->createDailyMeet($teacher, $date);
            if (! filled($created->meetUrl)) {
                $existing->update(['status' => TeacherDailyMeetingStatus::Failed->value]);
                throw new ApiException(
                    ErrorCode::MEETING_CREATE_FAILED,
                    'Unable to create the meeting right now. Please try again.',
                    503,
                );
            }

            $existing->update([
                'google_event_id' => $created->googleEventId,
                'google_meeting_space_id' => $created->googleMeetingSpaceId,
                'meet_url' => ($existing->meet_url_source === 'manual' && filled($existing->meet_url))
                    ? $existing->meet_url
                    : $created->meetUrl,
                'google_meet_url' => $created->meetUrl,
                'meet_url_source' => ($existing->meet_url_source === 'manual' && filled($existing->meet_url))
                    ? 'manual'
                    : 'google',
                'status' => TeacherDailyMeetingStatus::Ready->value,
            ]);

            return $existing->fresh() ?? $existing;
        });
    }

    public function setManualUrl(TeacherProfile $teacher, string $date, string $url): TeacherDailyMeeting
    {
        $meeting = $this->findOrCreateRow($teacher, $date);
        $meeting->update([
            'meet_url' => $url,
            'meet_url_source' => 'manual',
            'status' => TeacherDailyMeetingStatus::Ready->value,
        ]);

        return $meeting->fresh() ?? $meeting;
    }

    public function clearManualUrl(TeacherProfile $teacher, string $date): TeacherDailyMeeting
    {
        $meeting = $this->findOrCreateRow($teacher, $date);
        $googleUrl = $meeting->google_meet_url;
        $meeting->update([
            'meet_url' => $googleUrl,
            'meet_url_source' => 'google',
            'status' => filled($googleUrl)
                ? TeacherDailyMeetingStatus::Ready->value
                : TeacherDailyMeetingStatus::Pending->value,
        ]);

        return $meeting->fresh() ?? $meeting;
    }

    private function findOrCreateRow(TeacherProfile $teacher, string $date): TeacherDailyMeeting
    {
        $existing = TeacherDailyMeeting::query()
            ->where('teacher_id', $teacher->id)
            ->whereDate('date', $date)
            ->first();

        if ($existing !== null) {
            return $existing;
        }

        return TeacherDailyMeeting::query()->create([
            'teacher_id' => $teacher->id,
            'date' => $date,
            'status' => TeacherDailyMeetingStatus::Pending->value,
            'meet_url_source' => 'google',
        ]);
    }

    public function urlFor(string $teacherId, string $date): ?string
    {
        return TeacherDailyMeeting::query()
            ->where('teacher_id', $teacherId)
            ->whereDate('date', $date)
            ->where('status', TeacherDailyMeetingStatus::Ready->value)
            ->value('meet_url');
    }
}
