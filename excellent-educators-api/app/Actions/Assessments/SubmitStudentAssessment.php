<?php

namespace App\Actions\Assessments;

use App\Enums\AptitudeAssessmentStatus;
use App\Enums\AssessmentAttemptStatus;
use App\Exceptions\ApiException;
use App\Models\AptitudeAssessment;
use App\Models\AptitudeAssessmentAnswer;
use App\Models\AptitudeAssessmentAttempt;
use App\Models\AptitudeAssessmentOption;
use App\Models\AptitudeAssessmentQuestion;
use App\Models\AptitudeAssessmentResult;
use App\Models\AptitudeAssessmentResultDimension;
use App\Models\StudentProfile;
use App\Support\ErrorCode;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class SubmitStudentAssessment
{
    public function __construct(private readonly CalculateAssessmentResult $calculateAssessmentResult) {}

    /**
     * @param  list<array{question_id: string, option_id: string}>  $answers
     */
    public function execute(StudentProfile $student, AptitudeAssessment $assessment, array $answers): AptitudeAssessmentResult
    {
        try {
            return DB::transaction(function () use ($student, $assessment, $answers) {
                $assessment = AptitudeAssessment::query()
                    ->whereKey($assessment->id)
                    ->lockForUpdate()
                    ->firstOrFail();

                $this->assertEligible($student, $assessment);

                $existing = AptitudeAssessmentAttempt::query()
                    ->where('aptitude_assessment_id', $assessment->id)
                    ->where('student_id', $student->id)
                    ->where('status', AssessmentAttemptStatus::Submitted->value)
                    ->lockForUpdate()
                    ->first();

                if ($existing !== null) {
                    throw new ApiException(
                        ErrorCode::ASSESSMENT_ALREADY_SUBMITTED,
                        'This assessment has already been submitted.',
                        409,
                    );
                }

                $assessment->load(['questions.options']);
                $mapped = $this->validateAnswers($assessment, $answers);

                $now = now();
                $attempt = AptitudeAssessmentAttempt::query()->create([
                    'aptitude_assessment_id' => $assessment->id,
                    'student_id' => $student->id,
                    'started_at' => $now,
                    'submitted_at' => $now,
                    'status' => AssessmentAttemptStatus::Submitted,
                ]);

                $storedAnswers = [];
                foreach ($mapped as $row) {
                    $storedAnswers[] = AptitudeAssessmentAnswer::query()->create([
                        'aptitude_assessment_attempt_id' => $attempt->id,
                        'aptitude_assessment_question_id' => $row['question']->id,
                        'aptitude_assessment_option_id' => $row['option']->id,
                    ]);
                }

                $answersWithOptions = AptitudeAssessmentAnswer::query()
                    ->where('aptitude_assessment_attempt_id', $attempt->id)
                    ->with('option.dimensionCodes')
                    ->get();

                $scores = $this->calculateAssessmentResult->execute($answersWithOptions);

                $result = AptitudeAssessmentResult::query()->create([
                    'aptitude_assessment_attempt_id' => $attempt->id,
                    'student_id' => $student->id,
                    'calculated_at' => $now,
                ]);

                foreach ($scores as $code => $score) {
                    AptitudeAssessmentResultDimension::query()->create([
                        'aptitude_assessment_result_id' => $result->id,
                        'dimension_code' => $code,
                        'score' => $score,
                    ]);
                }

                return $result->fresh([
                    'dimensions',
                    'attempt.assessment.careerCompassLevel',
                    'student',
                ]) ?? $result;
            });
        } catch (UniqueConstraintViolationException) {
            throw new ApiException(
                ErrorCode::ASSESSMENT_ALREADY_SUBMITTED,
                'This assessment has already been submitted.',
                409,
            );
        }
    }

    private function assertEligible(StudentProfile $student, AptitudeAssessment $assessment): void
    {
        if ($assessment->status !== AptitudeAssessmentStatus::Active) {
            throw new ApiException(
                ErrorCode::ASSESSMENT_NOT_ACTIVE,
                'This assessment is not available.',
                422,
            );
        }

        if ($assessment->career_compass_level_id !== $student->career_compass_level_id) {
            throw new ApiException(
                ErrorCode::ASSESSMENT_LEVEL_MISMATCH,
                'This assessment does not match the student Career Compass level.',
                422,
            );
        }
    }

    /**
     * @param  list<array{question_id?: mixed, option_id?: mixed}>  $answers
     * @return list<array{question: AptitudeAssessmentQuestion, option: AptitudeAssessmentOption}>
     */
    private function validateAnswers(AptitudeAssessment $assessment, array $answers): array
    {
        $questions = $assessment->questions;
        if ($questions->isEmpty()) {
            throw new ApiException(
                ErrorCode::ASSESSMENT_INCOMPLETE,
                'This assessment has no questions.',
                422,
            );
        }

        $answersByQuestion = [];
        foreach ($answers as $index => $answer) {
            $questionId = is_string($answer['question_id'] ?? null) ? $answer['question_id'] : null;
            if ($questionId === null) {
                throw ValidationException::withMessages([
                    "answers.{$index}.question_id" => 'The question ID is required.',
                ]);
            }
            if (isset($answersByQuestion[$questionId])) {
                throw ValidationException::withMessages([
                    "answers.{$index}.question_id" => 'Each question may only be answered once.',
                ]);
            }
            $answersByQuestion[$questionId] = $answer;
        }

        $mapped = [];
        foreach ($questions as $question) {
            if (! isset($answersByQuestion[$question->id])) {
                throw new ApiException(
                    ErrorCode::ASSESSMENT_INCOMPLETE,
                    'All questions are compulsory.',
                    422,
                    ['missing_question_id' => $question->id],
                );
            }

            $optionId = $answersByQuestion[$question->id]['option_id'] ?? null;
            $option = $question->options->firstWhere('id', $optionId);
            if (! $option instanceof AptitudeAssessmentOption) {
                throw ValidationException::withMessages([
                    'answers' => 'Each selected option must belong to the corresponding question.',
                ]);
            }

            $mapped[] = [
                'question' => $question,
                'option' => $option,
            ];
        }

        if (count($answersByQuestion) !== $questions->count()) {
            throw new ApiException(
                ErrorCode::ASSESSMENT_INCOMPLETE,
                'All questions are compulsory.',
                422,
            );
        }

        return $mapped;
    }
}
