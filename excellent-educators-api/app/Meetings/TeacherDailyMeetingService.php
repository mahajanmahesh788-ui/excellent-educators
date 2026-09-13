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
                'meet_url' => $created->meetUrl,
                'status' => TeacherDailyMeetingStatus::Ready->value,
            ]);

            return $existing->fresh() ?? $existing;
        });
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
