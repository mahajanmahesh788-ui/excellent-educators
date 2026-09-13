<?php

namespace App\Meetings;

use App\Models\TeacherProfile;

interface GoogleMeetGateway
{
    public function createDailyMeet(TeacherProfile $teacher, string $date): CreatedGoogleMeet;
}
