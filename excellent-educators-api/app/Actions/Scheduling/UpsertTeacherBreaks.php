<?php

namespace App\Actions\Scheduling;

use App\Enums\TeacherBreakType;
use App\Exceptions\ApiException;
use App\Models\TeacherBreak;
use App\Models\TeacherProfile;
use App\Scheduling\SlotGrid;
use App\Support\ErrorCode;
use Illuminate\Support\Facades\DB;

class UpsertTeacherBreaks
{
    /**
     * @param  array{breakfast_start?: string|null, lunch_start?: string|null}  $payload
     * @return \Illuminate\Support\Collection<int, TeacherBreak>
     */
    public function execute(TeacherProfile $teacher, array $payload)
    {
        $breakfast = $payload['breakfast_start'] ?? null;
        $lunch = $payload['lunch_start'] ?? null;

        $this->assertBreak($breakfast, 'Breakfast', '06:00', '10:00');
        $this->assertBreak($lunch, 'Lunch', '12:00', '15:00');

        if (is_string($breakfast) && is_string($lunch)) {
            $bStart = SlotGrid::parseHm($breakfast);
            $bEnd = $bStart + SlotGrid::breakMinutes();
            $lStart = SlotGrid::parseHm($lunch);
            $lEnd = $lStart + SlotGrid::breakMinutes();
            if ($bStart < $lEnd && $lStart < $bEnd) {
                throw new ApiException(ErrorCode::VALIDATION_ERROR, 'Breakfast and lunch cannot overlap.', 422);
            }
        }

        return DB::transaction(function () use ($teacher, $breakfast, $lunch) {
            $this->upsert($teacher, TeacherBreakType::Breakfast, $breakfast);
            $this->upsert($teacher, TeacherBreakType::Lunch, $lunch);

            return TeacherBreak::query()->where('teacher_id', $teacher->id)->orderBy('start_time')->get();
        });
    }

    private function upsert(TeacherProfile $teacher, TeacherBreakType $type, ?string $start): void
    {
        if ($start === null || $start === '') {
            TeacherBreak::query()->where('teacher_id', $teacher->id)->where('type', $type->value)->delete();

            return;
        }

        $end = SlotGrid::addMinutes($start, SlotGrid::breakMinutes());
        TeacherBreak::query()->updateOrCreate(
            ['teacher_id' => $teacher->id, 'type' => $type->value],
            [
                'start_time' => $start.':00',
                'end_time' => $end.':00',
                'is_recurring' => true,
            ],
        );
    }

    private function assertBreak(?string $start, string $label, string $windowStart, string $windowEnd): void
    {
        if ($start === null || $start === '') {
            return;
        }
        if (SlotGrid::parseHm($start) % 60 !== 0) {
            throw new ApiException(ErrorCode::VALIDATION_ERROR, "{$label} must be a full hour (for example 1:00–2:00).", 422);
        }
        $end = SlotGrid::addMinutes($start, SlotGrid::breakMinutes());
        if (! SlotGrid::isWithinDay($start, $end)) {
            throw new ApiException(
                ErrorCode::VALIDATION_ERROR,
                "{$label} must fit within ".SlotGrid::dayStart().' and '.SlotGrid::dayEnd().'.',
                422,
            );
        }
        if (SlotGrid::parseHm($start) < SlotGrid::parseHm($windowStart)
            || SlotGrid::parseHm($start) > SlotGrid::parseHm($windowEnd)) {
            throw new ApiException(
                ErrorCode::VALIDATION_ERROR,
                "{$label} can start between {$windowStart} and {$windowEnd}.",
                422,
            );
        }
    }
}
