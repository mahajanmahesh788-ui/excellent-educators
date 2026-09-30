<?php

namespace App\Http\Controllers\Api\V1\Concerns;

use App\Models\StudentProfile;
use Illuminate\Http\Request;

trait EnsuresAgentOwnsStudent
{
    protected function ensureAgentOwnsStudent(Request $request, StudentProfile $student): void
    {
        $actor = $request->user();
        if ($actor === null || ! $actor->isAgent()) {
            return;
        }

        if ($student->created_by_user_id !== $actor->id) {
            abort(404);
        }
    }

    protected function agentOwnsStudent(?\App\Models\User $actor, StudentProfile $student): bool
    {
        if ($actor === null || ! $actor->isAgent()) {
            return true;
        }

        return $student->created_by_user_id === $actor->id;
    }
}
