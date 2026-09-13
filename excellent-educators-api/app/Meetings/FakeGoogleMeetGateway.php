<?php

namespace App\Meetings;

use App\Models\TeacherProfile;

class FakeGoogleMeetGateway implements GoogleMeetGateway
{
    public int $createCount = 0;

    public function createDailyMeet(TeacherProfile $teacher, string $date): CreatedGoogleMeet
    {
        $this->createCount++;
        $slug = substr(hash('sha256', $teacher->id.'|'.$date), 0, 12);

        return new CreatedGoogleMeet(
            meetUrl: 'https://meet.google.com/'.$slug,
            googleEventId: 'fake-event-'.$teacher->id.'-'.$date,
            googleMeetingSpaceId: 'fake-space-'.$slug,
        );
    }
}
