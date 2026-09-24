<?php

namespace App\Support;

use App\Enums\RoleName;
use App\Models\AcademicLevel;
use App\Models\AdminActivityEvent;
use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class AdminActivity
{
    public static function record(
        User $actor,
        string $type,
        string $message,
        mixed $related = null,
        array $meta = [],
    ): AdminActivityEvent {
        return AdminActivityEvent::query()->create([
            'actor_id' => $actor->id,
            'type' => $type,
            'message' => $message,
            'occurred_at' => AppClock::now(),
            'related_type' => is_object($related) ? $related::class : null,
            'related_id' => is_object($related) && isset($related->id) ? (string) $related->id : null,
            'meta' => $meta === [] ? null : $meta,
        ]);
    }

    public static function fromRequest(Request $request, ?array $responseData = null): void
    {
        $user = $request->user();
        if ($user === null || ! $user->hasRole(RoleName::SubAdmin->value)) {
            return;
        }

        $method = strtoupper($request->method());
        if (in_array($method, ['GET', 'HEAD', 'OPTIONS'], true)) {
            return;
        }

        $path = self::path($request);
        if (Str::is('admin/sub-admins*', $path)) {
            return;
        }

        [$type, $message, $related, $meta] = self::describe($request, $method, $path, $responseData);
        self::record($user, $type, $message, $related, array_merge([
            'method' => $method,
            'path' => $path,
        ], $meta));
    }

    /**
     * @return array{0: string, 1: string, 2: mixed, 3: array<string, mixed>}
     */
    private static function describe(Request $request, string $method, string $path, ?array $responseData = null): array
    {
        $student = $request->route('student');
        $teacher = $request->route('teacher');
        $level = $request->route('level');
        $batch = $request->route('batch');
        $issue = $request->route('issue');
        $adminRequest = $request->route('adminRequest');
        $assessment = $request->route('aptitudeAssessment');
        $booking = $request->route('booking');
        $studentName = self::label($student, 'full_name', $request->input('name'));
        $teacherName = self::label($teacher, 'full_name', $request->input('name'));

        if (Str::is('admin/students/*/promote', $path)) {
            $to = $request->input('level_id');
            $levelName = is_string($to)
                ? (AcademicLevel::query()->find($to)?->name ?? 'a new level')
                : 'a new level';

            return ['student.promote', "Updated {$studentName} to {$levelName}", $student, []];
        }
        if (Str::is('admin/students/*/mentor', $path) && $method === 'DELETE') {
            return ['student.mentor', "Removed master teacher from {$studentName}", $student, []];
        }
        if (Str::is('admin/students/*/mentor', $path)) {
            return ['student.mentor', "Assigned a master teacher to {$studentName}", $student, []];
        }
        if (Str::is('admin/students/*/feedback*', $path)) {
            $verb = $method === 'DELETE' ? 'Deleted' : ($method === 'POST' ? 'Added' : 'Edited');

            return ['student.rating', "{$verb} monthly rating for {$studentName}", $student, []];
        }
        if ($path === 'admin/students' && $method === 'POST') {
            $createdName = is_string($responseData['full_name'] ?? null)
                ? $responseData['full_name']
                : $studentName;
            $createdId = is_string($responseData['id'] ?? null) ? $responseData['id'] : null;

            return [
                'student.create',
                "Created student login for {$createdName}",
                null,
                array_filter([
                    'student_name' => $createdName !== '' ? $createdName : null,
                    'student_id' => $createdId,
                ]),
            ];
        }
        if (Str::is('admin/students/*', $path) && $method === 'DELETE') {
            return ['student.delete', "Deleted student {$studentName}", $student, []];
        }
        if (Str::is('admin/students/*', $path)) {
            return ['student.edit', "Edited student {$studentName}", $student, []];
        }

        if ($path === 'admin/teachers' && $method === 'POST') {
            return ['teacher.create', "Created teacher login for {$teacherName}", $teacher, []];
        }
        if (Str::is('admin/teachers/*', $path) && $method === 'DELETE') {
            return ['teacher.delete', "Deleted teacher {$teacherName}", $teacher, []];
        }
        if (Str::is('admin/teachers/*', $path)) {
            return ['teacher.edit', "Edited teacher {$teacherName}", $teacher, []];
        }
        if (Str::is('admin/schedule*', $path)) {
            return ['teacher.schedule', self::scheduleMessage($method, $path, $teacherName), $teacher ?? $booking, []];
        }

        if (Str::is('admin/attendance/*/resolve', $path)) {
            return ['query.resolve', 'Resolved a class conflict / query', $issue, []];
        }

        if (Str::is('admin/requests/*/resolve', $path)) {
            return ['request.resolve', 'Resolved an admin request', $adminRequest, []];
        }

        if (Str::is('admin/assessments*', $path)) {
            $title = self::label($assessment, 'title', $request->input('title')) ?: 'an assessment';

            return ['assessment.manage', self::verb($method).' assessment '.$title, $assessment, []];
        }

        if (Str::is('admin/levels*', $path) || Str::is('admin/batches*', $path)) {
            $name = self::label($level, 'name', $request->input('name'))
                ?: self::label($batch, 'name', $request->input('name'))
                ?: 'a level or batch';

            if (Str::contains($path, 'students') && $method === 'POST') {
                return ['level.enroll', "Enrolled a student into {$name}", $batch ?? $level, []];
            }
            if (Str::contains($path, 'students') && $method === 'DELETE') {
                return ['level.unenroll', "Removed a student from {$name}", $batch ?? $level, []];
            }
            if (Str::contains($path, 'teachers')) {
                return ['level.teachers', self::verb($method).' master teacher on '.$name, $level, []];
            }
            if (Str::contains($path, 'weekly-learnings')) {
                return ['level.learning', "Updated weekly learning for {$name}", $level, []];
            }

            return ['level.manage', self::verb($method).' '.$name, $level ?? $batch, []];
        }

        if (Str::is('admin/settings*', $path) || Str::is('admin/login-page*', $path) || Str::is('admin/site-pages*', $path) || Str::is('admin/google*', $path)) {
            return ['settings.manage', 'Updated academy settings', null, []];
        }

        return ['admin.action', self::verb($method).' '.$path, null, []];
    }

    private static function scheduleMessage(string $method, string $path, string $teacherName): string
    {
        if (Str::contains($path, 'leaves')) {
            return $method === 'DELETE'
                ? 'Removed a teacher leave'
                : 'Recorded a teacher leave'.($teacherName !== '' ? " for {$teacherName}" : '');
        }
        if (Str::contains($path, 'breaks')) {
            return 'Updated teacher breaks'.($teacherName !== '' ? " for {$teacherName}" : '');
        }
        if (Str::contains($path, 'availability')) {
            return 'Updated teacher availability'.($teacherName !== '' ? " for {$teacherName}" : '');
        }
        if (Str::contains($path, 'bookings') && $method === 'POST') {
            return 'Created a session booking';
        }
        if (Str::contains($path, 'bookings') && $method === 'DELETE') {
            return 'Cancelled a session booking';
        }
        if (Str::contains($path, 'complete')) {
            return 'Marked a session complete';
        }
        if (Str::contains($path, 'bookings')) {
            return 'Updated a session booking';
        }

        return 'Updated teacher schedule';
    }

    private static function verb(string $method): string
    {
        return match ($method) {
            'POST' => 'Created',
            'DELETE' => 'Deleted',
            default => 'Updated',
        };
    }

    private static function label(mixed $model, string $attribute, mixed $fallback): string
    {
        if ($model instanceof Model) {
            $value = $model->getAttribute($attribute);
            if (is_string($value) && $value !== '') {
                return $value;
            }
        }

        return is_string($fallback) && $fallback !== '' ? $fallback : '';
    }

    private static function path(Request $request): string
    {
        $path = ltrim($request->path(), '/');

        return Str::startsWith($path, 'api/v1/')
            ? substr($path, strlen('api/v1/'))
            : $path;
    }
}
