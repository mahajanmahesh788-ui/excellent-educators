<?php

namespace App\Actions\Assessments;

use App\Actions\Notifications\CreateUserNotification;
use App\Enums\AptitudeAssessmentStatus;
use App\Enums\AssessmentAttemptStatus;
use App\Enums\NotificationType;
use App\Enums\ProfileStatus;
use App\Enums\RoleName;
use App\Exceptions\ApiException;
use App\Models\AptitudeAssessment;
use App\Models\StudentProfile;
use App\Models\User;
use App\Support\ErrorCode;
use Throwable;

class ActivateAptitudeAssessment
{
    public function __construct(
        private readonly CreateUserNotification $notifications,
    ) {}

    public function execute(AptitudeAssessment $assessment, User $actor): AptitudeAssessment
    {
        $assessment->load(['questions.options.dimensionCodes']);

        if (! $assessment->isComplete()) {
            throw new ApiException(
                ErrorCode::ASSESSMENT_NOT_READY,
                'Assessment cannot be activated until every question has options with one to three valid dimension codes.',
                422,
            );
        }

        $assessment->status = AptitudeAssessmentStatus::Active;
        $assessment->updated_by = $actor->id;
        $assessment->save();

        $this->notifyEligibleStudents($assessment);

        return $assessment->fresh(['questions.options.dimensionCodes']) ?? $assessment;
    }

    private function notifyEligibleStudents(AptitudeAssessment $assessment): void
    {
        try {
            $submittedStudentIds = \App\Models\AptitudeAssessmentAttempt::query()
                ->where('aptitude_assessment_id', $assessment->id)
                ->where('status', AssessmentAttemptStatus::Submitted->value)
                ->pluck('student_id');

            StudentProfile::query()
                ->where('status', ProfileStatus::Active->value)
                ->whereHas('user', fn ($query) => $query->role(RoleName::Student->value))
                ->when($submittedStudentIds->isNotEmpty(), fn ($query) => $query->whereNotIn('id', $submittedStudentIds))
                ->with('user')
                ->chunkById(100, function ($students) use ($assessment): void {
                    foreach ($students as $student) {
                        $user = $student->user;
                        if ($user === null) {
                            continue;
                        }
                        $this->notifications->execute(
                            $user,
                            NotificationType::AptitudeAssessmentAvailable,
                            'New aptitude assessment',
                            "{$assessment->title} is ready for you.",
                            [
                                'assessment_id' => $assessment->id,
                                'assessment_title' => $assessment->title,
                                'link' => '/student/dashboard',
                            ],
                        );
                    }
                });
        } catch (Throwable) {
            // Activation must succeed even if notify fails.
        }
    }
}
