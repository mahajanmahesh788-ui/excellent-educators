<?php

namespace App\Http\Controllers\Api\V1\Student;

use App\Actions\Onboarding\SkipParentIntake;
use App\Actions\Onboarding\SubmitInterestProfile;
use App\Actions\Onboarding\SubmitParentIntake;
use App\Exceptions\ApiException;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Onboarding\SubmitInterestProfileRequest;
use App\Http\Requests\Api\V1\Onboarding\SubmitParentIntakeRequest;
use App\Http\Resources\Api\V1\UserResource;
use App\Models\InterestQuestion;
use App\Models\InterestResponse;
use App\Models\ParentQuestion;
use App\Models\ParentResponse;
use App\Models\User;
use App\Support\ApiResponse;
use App\Support\ErrorCode;
use App\Support\StudentOnboardingStatus;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class OnboardingController extends Controller
{
    public function interestShow(Request $request): JsonResponse
    {
        $student = $this->student($request);
        $questions = InterestQuestion::query()
            ->with(['options' => fn ($query) => $query->where('is_active', true)->orderBy('display_order')])
            ->where('is_active', true)
            ->orderBy('display_order')
            ->get();

        $response = InterestResponse::query()
            ->with(['answers.options'])
            ->where('student_id', $student->id)
            ->first();

        $savedAnswers = [];
        if ($response !== null) {
            foreach ($response->answers as $ans) {
                $savedAnswers[$ans->interest_question_id] = [
                    'option_ids' => $ans->options->pluck('id')->values()->all(),
                    'other_text' => $ans->other_text ?? '',
                ];
            }
        }

        return ApiResponse::success('Interest profile fetched successfully.', [
            'completed' => $response !== null,
            'questions' => $questions->map(fn (InterestQuestion $question) => [
                'id' => $question->id,
                'question_text' => $question->question_text,
                'allow_other' => $question->allow_other,
                'max_selections' => $question->max_selections,
                'options' => $question->options->map(fn ($option) => [
                    'id' => $option->id,
                    'option_text' => $option->option_text,
                ])->values()->all(),
            ])->values()->all(),
            'saved_answers' => (object) $savedAnswers,
            'onboarding' => StudentOnboardingStatus::forStudent($student),
        ]);
    }

    public function interestStore(SubmitInterestProfileRequest $request, SubmitInterestProfile $submit): JsonResponse
    {
        $student = $this->student($request);
        $submit->execute($student, $request->validated('answers'));

        return $this->userPayload($request->user(), 'Interest profile saved successfully.');
    }

    public function parentShow(Request $request): JsonResponse
    {
        $student = $this->student($request);
        $questions = ParentQuestion::query()
            ->with(['options' => fn ($query) => $query->where('is_active', true)->orderBy('display_order')])
            ->where('is_active', true)
            ->orderBy('display_order')
            ->get();

        $response = ParentResponse::query()
            ->with(['answers'])
            ->where('student_id', $student->id)
            ->first();

        $savedAnswers = [];
        if ($response !== null) {
            foreach ($response->answers as $ans) {
                $savedAnswers[$ans->parent_question_id] = [
                    'option_id' => $ans->parent_option_id,
                    'text_answer' => $ans->text_answer ?? '',
                ];
            }
        }

        return ApiResponse::success('Parent intake fetched successfully.', [
            'completed' => $response?->isCompleted() ?? false,
            'skipped' => $response?->isSkipped() ?? false,
            'questions' => $questions->map(fn (ParentQuestion $question) => [
                'id' => $question->id,
                'question_text' => $question->question_text,
                'question_type' => $question->question_type->value,
                'options' => $question->options->map(fn ($option) => [
                    'id' => $option->id,
                    'option_text' => $option->option_text,
                ])->values()->all(),
            ])->values()->all(),
            'saved_answers' => (object) $savedAnswers,
            'onboarding' => StudentOnboardingStatus::forStudent($student),
        ]);
    }

    public function parentStore(SubmitParentIntakeRequest $request, SubmitParentIntake $submit): JsonResponse
    {
        $student = $this->student($request);
        $submit->execute($student, $request->validated('answers'));

        return $this->userPayload($request->user(), 'Parent intake saved successfully.');
    }

    public function parentSkip(Request $request, SkipParentIntake $skip): JsonResponse
    {
        $student = $this->student($request);
        $skip->execute($student);

        return $this->userPayload($request->user(), 'Parent intake skipped for now.');
    }

    private function student(Request $request)
    {
        $student = $request->user()?->studentProfile;
        if ($student === null) {
            throw new ApiException(ErrorCode::FORBIDDEN, 'Student profile not found.', 403);
        }

        return $student;
    }

    private function userPayload(User $user, string $message): JsonResponse
    {
        $fresh = $user->fresh(['roles', 'permissions', 'adminProfile', 'studentProfile']);

        return ApiResponse::success($message, (new UserResource($fresh))->resolve());
    }
}
