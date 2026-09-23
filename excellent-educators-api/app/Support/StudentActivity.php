<?php

namespace App\Support;

use App\Models\StudentActivityEvent;
use App\Models\StudentProfile;
use App\Models\User;

class StudentActivity
{
    public static function record(
        StudentProfile $student,
        string $type,
        string $message,
        ?User $actor = null,
        mixed $related = null,
        array $meta = [],
        ?\DateTimeInterface $occurredAt = null,
    ): StudentActivityEvent {
        return StudentActivityEvent::query()->create([
            'student_id' => $student->id,
            'type' => $type,
            'message' => $message,
            'occurred_at' => $occurredAt ?? AppClock::now(),
            'actor_id' => $actor?->id,
            'related_type' => is_object($related) ? $related::class : null,
            'related_id' => is_object($related) && isset($related->id) ? $related->id : null,
            'meta' => $meta === [] ? null : $meta,
        ]);
    }
}
