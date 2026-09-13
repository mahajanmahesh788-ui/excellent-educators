<?php

namespace App\Scheduling;

use App\Enums\SessionBookingStatus;
use App\Enums\TeacherAvailabilityOverrideType;
use App\Enums\TeacherWorkType;
use App\Exceptions\ApiException;
use App\Models\SessionBooking;
use App\Models\TeacherAvailabilityOverride;
use App\Models\TeacherAvailabilityRule;
use App\Models\TeacherProfile;
use App\Support\ErrorCode;
use Illuminate\Support\Facades\DB;

/**
 * Availability is stored as time ranges, never as individual 30-minute rows.
 *
 * Slot alignment: clock-aligned 30-minute slots (HH:00 / HH:30). A slot is
 * inside a range only when the entire slot (start and end) sits within that range.
 * Example: 09:15–10:45 yields 09:30–10:00 and 10:00–10:30, not 09:00–09:30.
 *
 * Date priority: specific-date unavailable, then specific-date ranges,
 * then weekly ranges. Default full-time 06:00–20:00 is seeded on create
 * and used as a fallback when a teacher still has no weekly rows.
 */
class TeacherAvailability
{
    /**
     * @return list<array{start: string, end: string}>
     */
    public function defaultDayRanges(): array
    {
        $configured = config('excellent_educators.scheduling.default_weekly_ranges');
        if (is_array($configured) && $configured !== []) {
            return array_values(array_map(static fn ($range): array => [
                'start' => substr((string) ($range['start'] ?? SlotGrid::dayStart()), 0, 5),
                'end' => substr((string) ($range['end'] ?? SlotGrid::dayEnd()), 0, 5),
            ], $configured));
        }

        return [[
            'start' => SlotGrid::dayStart(),
            'end' => SlotGrid::dayEnd(),
        ]];
    }

    /**
     * @param  list<int>  $offWeekdays
     */
    public function seedDefaultWeekly(TeacherProfile $teacher, array $offWeekdays = []): void
    {
        if (TeacherAvailabilityRule::query()->where('teacher_id', $teacher->id)->exists()) {
            return;
        }

        $ranges = $this->defaultDayRanges();
        $rows = [];
        foreach (range(0, 6) as $weekday) {
            if (in_array($weekday, $offWeekdays, true)) {
                continue;
            }
            foreach ($ranges as $range) {
                $rows[] = [
                    'id' => (string) str()->ulid(),
                    'teacher_id' => $teacher->id,
                    'day_of_week' => $weekday,
                    'start_time' => $range['start'].':00',
                    'end_time' => $range['end'].':00',
                    'is_active' => true,
                    'created_at' => now(),
                    'updated_at' => now(),
                ];
            }
        }
        if ($rows !== []) {
            TeacherAvailabilityRule::query()->insert($rows);
        }
    }

    /**
     * @return list<array{start: string, end: string}>
     */
    public function rangesForDate(TeacherProfile $teacher, string $date): array
    {
        return $this->sourceForDate($teacher, $date)['ranges'];
    }

    /**
     * @return array{source: string, ranges: list<array{start: string, end: string}>}
     */
    public function sourceForDate(TeacherProfile $teacher, string $date): array
    {
        $overrides = TeacherAvailabilityOverride::query()
            ->where('teacher_id', $teacher->id)
            ->whereDate('date', $date)
            ->get();

        if ($overrides->contains(fn (TeacherAvailabilityOverride $row) => $row->type === TeacherAvailabilityOverrideType::Unavailable)) {
            return ['source' => 'date_unavailable', 'ranges' => []];
        }

        $available = $overrides->filter(
            fn (TeacherAvailabilityOverride $row) => $row->type === TeacherAvailabilityOverrideType::Available
                && $row->start_time
                && $row->end_time,
        );
        if ($available->isNotEmpty()) {
            return [
                'source' => 'date_override',
                'ranges' => $available->map(fn (TeacherAvailabilityOverride $row) => [
                    'start' => substr((string) $row->start_time, 0, 5),
                    'end' => substr((string) $row->end_time, 0, 5),
                ])->values()->all(),
            ];
        }

        $weekday = SlotGrid::atDate($date, '00:00')->dayOfWeek;
        $hasAnyRules = TeacherAvailabilityRule::query()->where('teacher_id', $teacher->id)->exists();
        if (! $hasAnyRules) {
            return [
                'source' => 'default',
                'ranges' => $this->defaultDayRanges(),
            ];
        }

        $ranges = TeacherAvailabilityRule::query()
            ->where('teacher_id', $teacher->id)
            ->where('day_of_week', $weekday)
            ->where('is_active', true)
            ->orderBy('start_time')
            ->get()
            ->map(fn (TeacherAvailabilityRule $rule) => [
                'start' => substr((string) $rule->start_time, 0, 5),
                'end' => substr((string) $rule->end_time, 0, 5),
            ])->values()->all();

        return [
            'source' => $ranges === [] ? 'weekly_off' : 'weekly',
            'ranges' => $ranges,
        ];
    }

    /**
     * @return array<string, mixed>
     */
    public function configFor(TeacherProfile $teacher): array
    {
        $teacher->loadMissing(['availabilityRules', 'availabilityOverrides']);
        $weekly = [];
        foreach (range(0, 6) as $weekday) {
            $ranges = $teacher->availabilityRules
                ->where('day_of_week', $weekday)
                ->where('is_active', true)
                ->sortBy('start_time')
                ->values()
                ->map(fn (TeacherAvailabilityRule $rule) => [
                    'id' => $rule->id,
                    'start' => substr((string) $rule->start_time, 0, 5),
                    'end' => substr((string) $rule->end_time, 0, 5),
                ])->all();
            $weekly[] = [
                'day_of_week' => $weekday,
                'label' => $this->weekdayLabel($weekday),
                'off' => $ranges === [],
                'ranges' => $ranges,
            ];
        }

        $overrides = $teacher->availabilityOverrides
            ->sortBy('date')
            ->values()
            ->map(fn (TeacherAvailabilityOverride $row) => [
                'id' => $row->id,
                'date' => $row->date?->toDateString(),
                'type' => $row->type?->value ?? $row->type,
                'start' => $row->start_time ? substr((string) $row->start_time, 0, 5) : null,
                'end' => $row->end_time ? substr((string) $row->end_time, 0, 5) : null,
            ])->all();

        return [
            'teacher_id' => $teacher->id,
            'teacher_name' => $teacher->full_name,
            'work_type' => $teacher->work_type?->value ?? TeacherWorkType::FullTime->value,
            'default_ranges' => $this->defaultDayRanges(),
            'weekly' => $weekly,
            'overrides' => $overrides,
        ];
    }

    /**
     * @param  array<string, mixed>  $payload
     * @return array<string, mixed>
     */
    public function replaceWeekly(TeacherProfile $teacher, array $payload): array
    {
        $days = $payload['weekly'] ?? [];
        if (! is_array($days)) {
            throw new ApiException(ErrorCode::VALIDATION_ERROR, 'Weekly availability is required.', 422);
        }

        return DB::transaction(function () use ($teacher, $payload, $days): array {
            if (isset($payload['work_type'])) {
                $teacher->update(['work_type' => TeacherWorkType::from((string) $payload['work_type'])->value]);
            }

            TeacherAvailabilityRule::query()->where('teacher_id', $teacher->id)->delete();
            $rows = [];
            foreach ($days as $day) {
                $weekday = (int) ($day['day_of_week'] ?? -1);
                if ($weekday < 0 || $weekday > 6) {
                    continue;
                }
                if (($day['off'] ?? false) === true) {
                    continue;
                }
                foreach ($day['ranges'] ?? [] as $range) {
                    $start = substr((string) ($range['start'] ?? ''), 0, 5);
                    $end = substr((string) ($range['end'] ?? ''), 0, 5);
                    $this->assertRange($start, $end);
                    $rows[] = [
                        'id' => (string) str()->ulid(),
                        'teacher_id' => $teacher->id,
                        'day_of_week' => $weekday,
                        'start_time' => $start.':00',
                        'end_time' => $end.':00',
                        'is_active' => true,
                        'created_at' => now(),
                        'updated_at' => now(),
                    ];
                }
            }
            if ($rows !== []) {
                TeacherAvailabilityRule::query()->insert($rows);
            }

            $teacher->refresh();

            return [
                ...$this->configFor($teacher),
                'booking_warnings' => $this->futureBookingWarnings($teacher),
            ];
        });
    }

    /**
     * @param  array<string, mixed>  $payload
     * @return array<string, mixed>
     */
    public function upsertOverride(TeacherProfile $teacher, array $payload): array
    {
        $date = (string) $payload['date'];
        $type = TeacherAvailabilityOverrideType::from((string) $payload['type']);

        return DB::transaction(function () use ($teacher, $payload, $date, $type): array {
            TeacherAvailabilityOverride::query()
                ->where('teacher_id', $teacher->id)
                ->whereDate('date', $date)
                ->delete();

            if ($type === TeacherAvailabilityOverrideType::Unavailable) {
                TeacherAvailabilityOverride::query()->create([
                    'teacher_id' => $teacher->id,
                    'date' => $date,
                    'type' => $type->value,
                    'start_time' => null,
                    'end_time' => null,
                ]);
            } else {
                $ranges = $payload['ranges'] ?? [];
                if ($ranges === [] && isset($payload['start'], $payload['end'])) {
                    $ranges = [['start' => $payload['start'], 'end' => $payload['end']]];
                }
                if ($ranges === []) {
                    throw new ApiException(ErrorCode::VALIDATION_ERROR, 'Add at least one time range for this date.', 422);
                }
                foreach ($ranges as $range) {
                    $start = substr((string) ($range['start'] ?? ''), 0, 5);
                    $end = substr((string) ($range['end'] ?? ''), 0, 5);
                    $this->assertRange($start, $end);
                    TeacherAvailabilityOverride::query()->create([
                        'teacher_id' => $teacher->id,
                        'date' => $date,
                        'type' => $type->value,
                        'start_time' => $start.':00',
                        'end_time' => $end.':00',
                    ]);
                }
            }

            $teacher->refresh();

            return [
                ...$this->configFor($teacher),
                'booking_warnings' => $this->futureBookingWarnings($teacher, $date),
            ];
        });
    }

    public function deleteOverride(TeacherProfile $teacher, string $overrideId): array
    {
        $row = TeacherAvailabilityOverride::query()
            ->where('teacher_id', $teacher->id)
            ->where('id', $overrideId)
            ->firstOrFail();
        $row->delete();

        return $this->configFor($teacher->refresh());
    }

    /**
     * @return list<array<string, mixed>>
     */
    public function futureBookingWarnings(TeacherProfile $teacher, ?string $onlyDate = null): array
    {
        $bookings = SessionBooking::query()
            ->where('teacher_id', $teacher->id)
            ->where('status', '!=', SessionBookingStatus::Cancelled->value)
            ->where('starts_at', '>', now())
            ->when($onlyDate, fn ($q) => $q->whereDate('date', $onlyDate))
            ->orderBy('starts_at')
            ->get();

        $warnings = [];
        foreach ($bookings as $booking) {
            $date = $booking->date?->toDateString();
            $start = SlotGrid::hmFrom($booking->starts_at);
            if ($date === null) {
                continue;
            }
            $ranges = $this->rangesForDate($teacher, $date);
            $fits = false;
            foreach ($ranges as $range) {
                if (SlotGrid::slotFitsRange($start, $range['start'], $range['end'])) {
                    $fits = true;
                    break;
                }
            }
            if (! $fits) {
                $warnings[] = [
                    'booking_id' => $booking->id,
                    'date' => $date,
                    'start' => $start,
                    'message' => 'An existing booking at '.$start.' on '.$date.' is outside the new availability. It was not cancelled.',
                ];
            }
        }

        return $warnings;
    }

    public function weekdayLabel(int $weekday): string
    {
        return ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'][$weekday] ?? 'Day';
    }

    private function assertRange(string $start, string $end): void
    {
        if (! preg_match('/^\d{2}:\d{2}$/', $start) || ! preg_match('/^\d{2}:\d{2}$/', $end)) {
            throw new ApiException(ErrorCode::VALIDATION_ERROR, 'Availability times must use HH:MM.', 422);
        }
        if (SlotGrid::parseHm($start) >= SlotGrid::parseHm($end)) {
            throw new ApiException(ErrorCode::VALIDATION_ERROR, 'Availability end time must be after start time.', 422);
        }
    }
}
