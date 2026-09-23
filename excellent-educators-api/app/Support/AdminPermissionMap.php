<?php

namespace App\Support;

use App\Enums\PermissionName;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

final class AdminPermissionMap
{
    /**
     * @return list<PermissionName>|null
     */
    public static function required(Request $request): ?array
    {
        $method = strtoupper($request->method());
        $path = self::path($request);

        if ($path === 'admin/dashboard') {
            return null;
        }

        foreach (self::rules() as [$methods, $pattern, $permissions]) {
            if (! in_array($method, $methods, true)) {
                continue;
            }
            if (Str::is($pattern, $path)) {
                return $permissions;
            }
        }

        return [PermissionName::SettingsManage];
    }

    private static function path(Request $request): string
    {
        $path = ltrim($request->path(), '/');

        return Str::startsWith($path, 'api/v1/')
            ? substr($path, strlen('api/v1/'))
            : $path;
    }

    /**
     * @return list<array{0: list<string>, 1: string, 2: list<PermissionName>}>
     */
    private static function rules(): array
    {
        $get = ['GET', 'HEAD'];
        $write = ['POST', 'PUT', 'PATCH', 'DELETE'];
        $all = ['GET', 'HEAD', 'POST', 'PUT', 'PATCH', 'DELETE'];

        return [
            [$all, 'admin/sub-admins*', [PermissionName::SubAdminsManage]],

            [$write, 'admin/students/*/promote', [PermissionName::StudentsPromote]],
            [$write, 'admin/students/*/mentor', [PermissionName::StudentsMentor]],
            [$write, 'admin/students/*/feedback*', [PermissionName::StudentsRating]],
            [['DELETE'], 'admin/students/*', [PermissionName::StudentsDelete]],
            [['POST'], 'admin/students', [PermissionName::StudentsCreate]],
            [['PUT', 'PATCH'], 'admin/students/*', [PermissionName::StudentsEdit]],
            [$get, 'admin/students*', [PermissionName::StudentsView, PermissionName::StudentsEdit, PermissionName::StudentsCreate, PermissionName::StudentsRating, PermissionName::StudentsPromote]],
            [$get, 'admin/feedback-catalog', [PermissionName::StudentsRating, PermissionName::StudentsView]],

            [$all, 'admin/schedule*', [PermissionName::TeachersSchedule]],
            [['DELETE'], 'admin/teachers/*', [PermissionName::TeachersDelete]],
            [['POST'], 'admin/teachers', [PermissionName::TeachersCreate]],
            [['PUT', 'PATCH'], 'admin/teachers/*', [PermissionName::TeachersEdit]],
            [$get, 'admin/teachers*', [PermissionName::TeachersView, PermissionName::TeachersEdit, PermissionName::TeachersCreate, PermissionName::TeachersSchedule]],

            [$write, 'admin/attendance/*/resolve', [PermissionName::QueriesResolve]],
            [$get, 'admin/attendance*', [PermissionName::QueriesView, PermissionName::QueriesResolve]],

            [$write, 'admin/requests/*/resolve', [PermissionName::RequestsResolve]],
            [$get, 'admin/requests*', [PermissionName::RequestsView, PermissionName::RequestsResolve]],

            [$write, 'admin/assessments*', [PermissionName::AssessmentsManage]],
            [$get, 'admin/assessments*', [PermissionName::AssessmentsView, PermissionName::AssessmentsManage]],

            [$write, 'admin/levels*', [PermissionName::LevelsManage]],
            [$write, 'admin/batches*', [PermissionName::LevelsManage]],
            [$get, 'admin/levels*', [PermissionName::LevelsView, PermissionName::LevelsManage]],
            [$get, 'admin/batches*', [PermissionName::LevelsView, PermissionName::LevelsManage]],

            [$all, 'admin/settings*', [PermissionName::SettingsManage]],
            [$all, 'admin/login-page*', [PermissionName::SettingsManage]],
            [$all, 'admin/google*', [PermissionName::SettingsManage]],
        ];
    }
}
