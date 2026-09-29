<?php

namespace App\Actions\Students;

use App\Models\AptitudeAssessmentAnswer;
use App\Models\AptitudeAssessmentAttempt;
use App\Models\AptitudeAssessmentResult;
use App\Models\AptitudeAssessmentResultDimension;
use App\Models\AssessmentScore;
use App\Models\BatchStudent;
use App\Models\MasterTeacherAssignment;
use App\Models\MonthlyFeedback;
use App\Models\MonthlyFeedbackItem;
use App\Models\StudentProfile;
use App\Models\User;
use App\Payments\PaymentPlanService;
use Illuminate\Support\Facades\DB;

class DeleteStudent
{
    public function __construct(
        private readonly PaymentPlanService $paymentPlans,
    ) {}

    /**
     * Hard-delete a student. Collected payments are kept forever; any pending
     * balance is written off as dead amount on the payment plan.
     *
     * @return array{dead_amount: float}
     */
    public function execute(StudentProfile $student, ?string $actorId = null): array
    {
        return DB::transaction(function () use ($student, $actorId): array {
            $deadAmount = $this->paymentPlans->writeOffOnStudentDelete($student, $actorId);

            // Clear restrictOnDelete relations so hard delete can succeed.
            BatchStudent::query()->where('student_id', $student->id)->delete();
            MasterTeacherAssignment::query()->where('student_id', $student->id)->delete();

            $feedbackIds = MonthlyFeedback::query()
                ->where('student_id', $student->id)
                ->pluck('id');
            if ($feedbackIds->isNotEmpty()) {
                MonthlyFeedbackItem::query()->whereIn('monthly_feedback_id', $feedbackIds)->delete();
                MonthlyFeedback::query()->whereIn('id', $feedbackIds)->delete();
            }

            AssessmentScore::query()->where('student_id', $student->id)->delete();

            $attemptIds = AptitudeAssessmentAttempt::query()
                ->where('student_id', $student->id)
                ->pluck('id');
            if ($attemptIds->isNotEmpty()) {
                $resultIds = AptitudeAssessmentResult::query()
                    ->whereIn('aptitude_assessment_attempt_id', $attemptIds)
                    ->pluck('id');
                if ($resultIds->isNotEmpty()) {
                    AptitudeAssessmentResultDimension::query()
                        ->whereIn('aptitude_assessment_result_id', $resultIds)
                        ->delete();
                    AptitudeAssessmentResult::query()->whereIn('id', $resultIds)->delete();
                }
                AptitudeAssessmentAnswer::query()
                    ->whereIn('aptitude_assessment_attempt_id', $attemptIds)
                    ->delete();
                AptitudeAssessmentAttempt::query()->whereIn('id', $attemptIds)->delete();
            }

            $user = $student->user;
            $student->forceDelete();
            if ($user instanceof User) {
                $user->forceDelete();
            }

            return ['dead_amount' => $deadAmount];
        });
    }
}
