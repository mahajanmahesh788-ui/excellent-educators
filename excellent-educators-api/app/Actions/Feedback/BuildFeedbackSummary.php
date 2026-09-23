<?php

namespace App\Actions\Feedback;

use App\Models\MonthlyFeedback;
use App\Models\MonthlyFeedbackItem;
use App\Models\StudentProfile;
use Illuminate\Support\Collection;

class BuildFeedbackSummary
{
    /**
     * @return array<string, mixed>
     */
    public function execute(StudentProfile $student): array
    {
        $sessions = MonthlyFeedback::query()
            ->where('student_id', $student->id)
            ->with('items')
            ->orderBy('year')
            ->orderBy('month')
            ->orderBy('session_date')
            ->get();

        $items = $sessions->flatMap(fn (MonthlyFeedback $session) => $session->items);

        $overallAverage = $sessions->isEmpty()
            ? null
            : round($sessions->avg(fn (MonthlyFeedback $session) => $session->sessionAverage() ?? 0), 1);
        $totalSessions = $sessions->count();

        return [
            'overall_average' => $overallAverage,
            'total_sessions' => $totalSessions,
            'by_month' => $this->byMonth($sessions),
            'by_dimension' => $this->byDimension($items),
        ];
    }

    /**
     * @param  Collection<int, MonthlyFeedback>  $sessions
     * @return list<array<string, mixed>>
     */
    private function byMonth(Collection $sessions): array
    {
        return $sessions
            ->groupBy(fn (MonthlyFeedback $session) => sprintf('%04d-%02d', $session->year, $session->month))
            ->map(function (Collection $group, string $key) {
                [$year, $month] = array_map('intval', explode('-', $key));
                $sessionAverages = $group
                    ->map(fn (MonthlyFeedback $session) => $session->sessionAverage())
                    ->filter();

                return [
                    'year' => $year,
                    'month' => $month,
                    'average_rating' => $sessionAverages->isEmpty() ? null : round($sessionAverages->avg(), 1),
                    'session_count' => $group->count(),
                ];
            })
            ->values()
            ->sortBy(fn (array $row) => ($row['year'] * 100) + $row['month'])
            ->values()
            ->all();
    }

    /**
     * @param  Collection<int, MonthlyFeedbackItem>  $items
     * @return list<array<string, mixed>>
     */
    private function byDimension(Collection $items): array
    {
        return $items
            ->groupBy(fn (MonthlyFeedbackItem $item) => ($item->target_type?->value ?? $item->target_type).':'.$item->target_id)
            ->map(function (Collection $group) {
                /** @var MonthlyFeedbackItem $first */
                $first = $group->first();

                return [
                    'target_type' => $first->target_type?->value ?? $first->target_type,
                    'target_id' => $first->target_id,
                    'target_name' => $first->resolveTargetName(),
                    'average_rating' => round($group->avg('rating'), 1),
                    'session_count' => $group->count(),
                ];
            })
            ->sortByDesc('average_rating')
            ->values()
            ->all();
    }
}
