<?php

namespace App\Meetings;

final class CreatedGoogleMeet
{
    public function __construct(
        public readonly string $meetUrl,
        public readonly ?string $googleEventId = null,
        public readonly ?string $googleMeetingSpaceId = null,
    ) {}
}
