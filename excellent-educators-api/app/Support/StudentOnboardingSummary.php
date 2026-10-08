<?php

namespace App\Support;

use App\Models\InterestResponse;
use App\Models\ParentOption;
use App\Models\ParentQuestion;
use App\Models\ParentResponse;
use App\Models\StudentProfile;
use Illuminate\Http\Request;

final class StudentOnboardingSummary
{
    public static function shouldInclude(Request $request): bool
    {
        $path = trim($request->path(), '/');

        if ($path === 'api/v1/student/profile') {
            return true;
        }

        // Single-student show only (not list/create/update collections).
        return (bool) preg_match(
            '#^api/v1/(?:admin|teacher|master-teacher)/students/[^/]+$#',
            $path,
        );
    }

    /**
     * @return array{
     *   interest_profile: array{completed: bool, answers: list<array{question: string, values: list<string>}>},
     *   parent_intake: array{available: bool, completed: bool, skipped: bool, answers: list<array{question: string, values: list<string>}>}
     * }
     */
    public static function forStudent(StudentProfile $student): array
    {
        return [
            'interest_profile' => self::interestProfile($student),
            'parent_intake' => self::parentIntake($student),
        ];
    }

    /**
     * @return array{completed: bool, answers: list<array{question: string, values: list<string>}>}
     */
    private static function interestProfile(StudentProfile $student): array
    {
        $response = InterestResponse::query()
            ->with(['answers' => fn ($q) => $q->with(['question', 'options'])->orderBy('id')])
            ->where('student_id', $student->id)
            ->first();

        if ($response === null) {
            return [
                'completed' => false,
                'answers' => [],
            ];
        }

        $answers = [];
        foreach ($response->answers as $answer) {
            $values = $answer->options->pluck('option_text')->filter()->values()->all();
            $other = trim((string) ($answer->other_text ?? ''));
            if ($other !== '') {
                $values[] = 'Other: '.$other;
            }

            $answers[] = [
                'question' => $answer->question?->question_text ?? 'Interest question',
                'values' => $values,
            ];
        }

        return [
            'completed' => true,
            'answers' => $answers,
        ];
    }

    /**
     * @return array{available: bool, completed: bool, skipped: bool, answers: list<array{question: string, values: list<string>}>}
     */
    private static function parentIntake(StudentProfile $student): array
    {
        $available = ParentQuestion::query()->where('is_active', true)->exists();

        $response = ParentResponse::query()
            ->with(['answers' => fn ($q) => $q->with(['question', 'option'])->orderBy('id')])
            ->where('student_id', $student->id)
            ->first();

        if ($response === null) {
            return [
                'available' => $available,
                'completed' => false,
                'skipped' => false,
                'answers' => [],
            ];
        }

        $answers = [];
        if ($response->isCompleted()) {
            foreach ($response->answers as $answer) {
                $value = trim((string) ($answer->text_answer ?? ''));
                if ($value === '') {
                    /** @var ParentOption|null $option */
                    $option = $answer->option;
                    $value = trim((string) ($option?->option_text ?? ''));
                }

                $answers[] = [
                    'question' => $answer->question?->question_text ?? 'Parent question',
                    'values' => $value !== '' ? [$value] : [],
                ];
            }
        }

        return [
            'available' => $available,
            'completed' => $response->isCompleted(),
            'skipped' => $response->isSkipped(),
            'answers' => $answers,
        ];
    }
}
