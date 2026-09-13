<?php

namespace App\Support;

use App\Models\AppSetting;

class AppSettings
{
    public const MAX_ACTIVE_STUDENTS = 'max_active_students';

    /**
     * Known settings. Add future keys here so Admin Settings can render them
     * without a new Flutter screen.
     *
     * @return list<array<string, mixed>>
     */
    public function catalog(): array
    {
        return [
            [
                'key' => self::MAX_ACTIVE_STUDENTS,
                'group' => 'batches',
                'group_label' => 'Batches',
                'label' => 'Maximum students per batch',
                'help' => 'Active students allowed in one batch before it is treated as full.',
                'type' => 'integer',
                'min' => 1,
                'max' => 500,
                'default' => (int) config('excellent_educators.batch.max_active_students', 50),
            ],
        ];
    }

    /**
     * @return array<string, mixed>
     */
    public function payload(): array
    {
        $values = $this->all();
        $items = [];
        foreach ($this->catalog() as $item) {
            $key = (string) $item['key'];
            $item['value'] = $values[$key] ?? $item['default'];
            $items[] = $item;
        }

        return [
            'max_active_students' => $this->maxActiveStudents(),
            'items' => $items,
        ];
    }

    /**
     * @param  array<string, mixed>  $incoming
     * @return array<string, mixed>
     */
    public function update(array $incoming, ?string $userId = null): array
    {
        $values = is_array($incoming['values'] ?? null) ? $incoming['values'] : [];
        foreach ($incoming as $key => $value) {
            if ($key !== 'values') {
                $values[$key] = $value;
            }
        }
        foreach ($this->catalog() as $item) {
            $key = (string) $item['key'];
            if (! array_key_exists($key, $values)) {
                continue;
            }
            AppSetting::query()->updateOrCreate(
                ['key' => $key],
                [
                    'value' => $this->serialize($item, $values[$key]),
                    'updated_by' => $userId,
                ],
            );
        }

        return $this->payload();
    }

    public function maxActiveStudents(): int
    {
        return (int) $this->get(self::MAX_ACTIVE_STUDENTS);
    }

    public function get(string $key): mixed
    {
        $values = $this->all();
        if (array_key_exists($key, $values)) {
            return $values[$key];
        }
        foreach ($this->catalog() as $item) {
            if ($item['key'] === $key) {
                return $item['default'];
            }
        }

        return null;
    }

    /**
     * @return array<string, mixed>
     */
    public function all(): array
    {
        $stored = AppSetting::query()->pluck('value', 'key');
        $out = [];
        foreach ($this->catalog() as $item) {
            $key = (string) $item['key'];
            $out[$key] = $stored->has($key)
                ? $this->cast($item, $stored[$key])
                : $item['default'];
        }

        return $out;
    }

    /**
     * @param  array<string, mixed>  $item
     */
    private function serialize(array $item, mixed $value): string
    {
        return match ($item['type']) {
            'integer' => (string) (int) $value,
            'boolean' => ((bool) $value) ? '1' : '0',
            default => (string) $value,
        };
    }

    /**
     * @param  array<string, mixed>  $item
     */
    private function cast(array $item, mixed $value): mixed
    {
        return match ($item['type']) {
            'integer' => (int) $value,
            'boolean' => $value === true || $value === 1 || $value === '1',
            default => $value,
        };
    }
}
