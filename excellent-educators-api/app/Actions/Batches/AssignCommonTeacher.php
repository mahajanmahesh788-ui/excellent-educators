<?php

namespace App\Actions\Batches;

use App\Actions\Notifications\DispatchAssignmentNotifications;
use App\Enums\RoleName;
use App\Exceptions\ApiException;
use App\Models\Batch;
use App\Models\BatchTeacher;
use App\Models\TeacherProfile;
use App\Models\User;
use App\Support\ErrorCode;
use Illuminate\Support\Facades\DB;

class AssignCommonTeacher
{
    public function __construct(
        private readonly DispatchAssignmentNotifications $dispatchAssignmentNotifications,
    ) {}

    public function execute(Batch $batch, TeacherProfile $teacher, User $actor): BatchTeacher
    {
        if (! $teacher->user->hasRole(RoleName::CommonTeacher->value)) {
            throw new ApiException(
                ErrorCode::VALIDATION_ERROR,
                'Only a Common Teacher can be assigned to a batch.',
                422,
            );
        }

        $previousTeacher = null;

        $assignment = DB::transaction(function () use ($batch, $teacher, $actor, &$previousTeacher): BatchTeacher {
            $current = BatchTeacher::query()
                ->where('batch_id', $batch->id)
                ->whereNull('ended_at')
                ->with('teacher')
                ->lockForUpdate()
                ->first();

            if ($current && $current->teacher_id === $teacher->id) {
                return $current;
            }

            if ($current) {
                $previousTeacher = $current->teacher;
                $current->update(['ended_at' => now()]);
            }

            return BatchTeacher::query()->create([
                'batch_id' => $batch->id,
                'teacher_id' => $teacher->id,
                'assigned_by' => $actor->id,
                'started_at' => now(),
                'created_at' => now(),
            ]);
        });

        if ($previousTeacher === null && $assignment->wasRecentlyCreated) {
            $this->dispatchAssignmentNotifications->commonTeacherAssigned($batch, $teacher);
        } elseif ($previousTeacher !== null) {
            $this->dispatchAssignmentNotifications->commonTeacherAssigned($batch, $teacher, $previousTeacher);
        }

        return $assignment;
    }
}
