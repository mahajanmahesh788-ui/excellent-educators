<?php

namespace App\Actions\Audit;

use App\Models\AuditLog;
use App\Models\User;
use Illuminate\Database\Eloquent\Model;

class RecordAuditEvent
{
    /**
     * @param  array<string, mixed>|null  $old
     * @param  array<string, mixed>|null  $new
     */
    public function execute(
        string $action,
        Model $subject,
        ?User $actor = null,
        ?array $old = null,
        ?array $new = null,
    ): AuditLog {
        $role = $actor?->roles->pluck('name')->first();

        return AuditLog::query()->create([
            'actor_id' => $actor?->id,
            'actor_role' => is_string($role) ? $role : null,
            'action' => $action,
            'subject_type' => $subject->getMorphClass(),
            'subject_id' => (string) $subject->getKey(),
            'old_values' => $old,
            'new_values' => $new,
            'request_id' => request()->headers->get('X-Request-Id')
                ?? request()->attributes->get('request_id'),
            'created_at' => now(),
        ]);
    }
}
