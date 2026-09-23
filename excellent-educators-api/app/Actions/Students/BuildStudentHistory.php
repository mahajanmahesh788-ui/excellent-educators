<?php

namespace App\Actions\Students;

use App\Enums\SessionBookingType;
use App\Models\AptitudeAssessmentAttempt;
use App\Models\SessionBooking;
use App\Models\StudentActivityEvent;
use App\Models\StudentLevelJourney;
use App\Models\StudentProfile;
use App\Models\WeeklyAssignmentAttempt;
use App\Support\AppClock;
use Illuminate\Support\Carbon;
use Illuminate\Support\Collection;

class BuildStudentHistory
{
    /**
     * @return list<array{occurred_at: string, type: string, message: string}>
     */
    public function execute(StudentProfile $student): array
    {
        $logged = StudentActivityEvent::query()
            ->where('student_id', $student->id)
            ->orderByDesc('occurred_at')
            ->get()
            ->map(fn (StudentActivityEvent $event) => $this->line(
                $event->occurred_at,
                $event->type,
                $event->message,
            ));

        $synthetic = collect()
            ->merge($this->fromBookings($student))
            ->merge($this->fromAssignments($student))
            ->merge($this->fromJourneys($student))
            ->merge($this->fromAssessments($student));

        $keys = $logged->map(fn (array $row) => $row['type'].'|'.$row['message'])->flip();
        $merged = $logged->concat(
            $synthetic->reject(fn (array $row) => $keys->has($row['type'].'|'.$row['message'])),
        );

        return $merged
            ->sortByDesc('occurred_at')
            ->values()
            ->all();
    }

    /**
     * @return Collection<int, array{occurred_at: string, type: string, message: string}>
     */
    private function fromBookings(StudentProfile $student): Collection
    {
        return SessionBooking::query()
            ->where('student_id', $student->id)
            ->orderBy('starts_at')
            ->get()
            ->flatMap(function (SessionBooking $booking) {
                $type = SessionBookingType::fromMixed($booking->type);
                $label = $type?->label() ?? 'Introduction Call';
                $when = $booking->starts_at?->timezone(config('app.timezone'));
                $time = AppClock::formatTime($booking->starts_at);
                $date = $when?->toIso8601String() ?? $booking->created_at?->toIso8601String();
                $isMaster = $type === SessionBookingType::MasterClass;
                $rows = [[
                    'occurred_at' => $booking->created_at?->toIso8601String() ?? $date,
                    'type' => $isMaster ? 'master_class_booked' : 'introduction_booked',
                    'message' => "Student booked a {$label}".($time !== '' ? " at {$time}" : ''),
                ]];
                $status = $booking->status?->value ?? (string) $booking->status;
                if ($status === 'completed') {
                    $rows[] = [
                        'occurred_at' => $booking->updated_at?->toIso8601String() ?? $date,
                        'type' => $isMaster ? 'master_class_attended' : 'introduction_attended',
                        'message' => "Student attended {$label}".($time !== '' ? " at {$time}" : ''),
                    ];
                }
                if ($status === 'cancelled') {
                    $rows[] = [
                        'occurred_at' => $booking->updated_at?->toIso8601String() ?? $date,
                        'type' => $isMaster ? 'master_class_cancelled' : 'introduction_cancelled',
                        'message' => "{$label} booking was cancelled",
                    ];
                }

                return $rows;
            });
    }

    /**
     * @return Collection<int, array{occurred_at: string, type: string, message: string}>
     */
    private function fromAssignments(StudentProfile $student): Collection
    {
        return WeeklyAssignmentAttempt::query()
            ->where('student_id', $student->id)
            ->orderBy('submitted_at')
            ->get()
            ->map(fn (WeeklyAssignmentAttempt $attempt) => $this->line(
                $attempt->submitted_at ?? $attempt->created_at,
                'assignment_submitted',
                'Student completed Week '.$attempt->week_number.' question answers (attempt '.$attempt->attempt_number.')',
            ));
    }

    /**
     * @return Collection<int, array{occurred_at: string, type: string, message: string}>
     */
    private function fromJourneys(StudentProfile $student): Collection
    {
        return StudentLevelJourney::query()
            ->with('level')
            ->where('student_id', $student->id)
            ->orderBy('started_at')
            ->get()
            ->map(function (StudentLevelJourney $journey) {
                $name = $journey->level?->name ?? 'a new level';

                return $this->line(
                    $journey->started_at ?? $journey->created_at,
                    'level_changed',
                    'Admin updated the student to '.$name,
                );
            });
    }

    /**
     * @return Collection<int, array{occurred_at: string, type: string, message: string}>
     */
    private function fromAssessments(StudentProfile $student): Collection
    {
        return AptitudeAssessmentAttempt::query()
            ->with('assessment')
            ->where('student_id', $student->id)
            ->whereNotNull('submitted_at')
            ->orderBy('submitted_at')
            ->get()
            ->map(function (AptitudeAssessmentAttempt $attempt) {
                $title = $attempt->assessment?->title ?? 'aptitude assessment';

                return $this->line(
                    $attempt->submitted_at,
                    'assessment_submitted',
                    'Student finished '.$title,
                );
            });
    }

    /**
     * @return array{occurred_at: string, type: string, message: string}
     */
    private function line(mixed $at, string $type, string $message): array
    {
        $iso = $at instanceof \DateTimeInterface
            ? Carbon::parse($at)->timezone(config('app.timezone'))->toIso8601String()
            : (string) ($at ?? AppClock::now()->toIso8601String());

        return [
            'occurred_at' => $iso,
            'type' => $type,
            'message' => $message,
        ];
    }
}
