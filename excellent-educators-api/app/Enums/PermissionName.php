<?php

namespace App\Enums;

enum PermissionName: string
{
    case AssessmentsManage = 'assessments.manage';
    case AssessmentsView = 'assessments.view';
    case FeedbackManage = 'feedback.manage';
    case FeedbackView = 'feedback.view';

    case StudentsView = 'students.view';
    case StudentsCreate = 'students.create';
    case StudentsEdit = 'students.edit';
    case StudentsDelete = 'students.delete';
    case StudentsPromote = 'students.promote';
    case StudentsRating = 'students.rating';
    case StudentsMentor = 'students.mentor';

    case TeachersView = 'teachers.view';
    case TeachersCreate = 'teachers.create';
    case TeachersEdit = 'teachers.edit';
    case TeachersDelete = 'teachers.delete';
    case TeachersSchedule = 'teachers.schedule';

    case LevelsView = 'levels.view';
    case LevelsManage = 'levels.manage';

    case QueriesView = 'queries.view';
    case QueriesResolve = 'queries.resolve';

    case RequestsView = 'requests.view';
    case RequestsResolve = 'requests.resolve';

    case SettingsManage = 'settings.manage';
    case SubAdminsManage = 'sub_admins.manage';

    public function group(): string
    {
        return match ($this) {
            self::StudentsView, self::StudentsCreate, self::StudentsEdit, self::StudentsDelete,
            self::StudentsPromote, self::StudentsRating, self::StudentsMentor => 'students',
            self::TeachersView, self::TeachersCreate, self::TeachersEdit, self::TeachersDelete,
            self::TeachersSchedule => 'teachers',
            self::LevelsView, self::LevelsManage => 'levels',
            self::QueriesView, self::QueriesResolve => 'queries',
            self::RequestsView, self::RequestsResolve => 'requests',
            self::AssessmentsView, self::AssessmentsManage => 'assessments',
            self::FeedbackView, self::FeedbackManage => 'ratings',
            self::SettingsManage => 'settings',
            self::SubAdminsManage => 'sub_admins',
        };
    }

    public function label(): string
    {
        return match ($this) {
            self::StudentsView => 'View students',
            self::StudentsCreate => 'Create student login',
            self::StudentsEdit => 'Edit student',
            self::StudentsDelete => 'Delete student',
            self::StudentsPromote => 'Update student to next level',
            self::StudentsRating => 'Edit student rating',
            self::StudentsMentor => 'Assign / remove master teacher',
            self::TeachersView => 'View teachers',
            self::TeachersCreate => 'Create teacher login',
            self::TeachersEdit => 'Edit teacher',
            self::TeachersDelete => 'Delete teacher',
            self::TeachersSchedule => 'Manage teacher schedule & bookings',
            self::LevelsView => 'View levels & batches',
            self::LevelsManage => 'Manage levels, batches & learning',
            self::QueriesView => 'View queries / class conflicts',
            self::QueriesResolve => 'Resolve queries / class conflicts',
            self::RequestsView => 'View admin requests',
            self::RequestsResolve => 'Resolve admin requests',
            self::AssessmentsView => 'View aptitude assessments',
            self::AssessmentsManage => 'Manage aptitude assessments',
            self::FeedbackView => 'View ratings',
            self::FeedbackManage => 'Manage ratings',
            self::SettingsManage => 'Manage settings',
            self::SubAdminsManage => 'Manage sub admins',
        };
    }

    /**
     * Toggles shown on the sub-admin editor. Ratings use students.rating.
     *
     * @return list<self>
     */
    public static function subAdminToggles(): array
    {
        return [
            self::StudentsView,
            self::StudentsCreate,
            self::StudentsEdit,
            self::StudentsDelete,
            self::StudentsPromote,
            self::StudentsRating,
            self::StudentsMentor,
            self::TeachersView,
            self::TeachersCreate,
            self::TeachersEdit,
            self::TeachersDelete,
            self::TeachersSchedule,
            self::LevelsView,
            self::LevelsManage,
            self::QueriesView,
            self::QueriesResolve,
            self::RequestsView,
            self::RequestsResolve,
            self::AssessmentsView,
            self::AssessmentsManage,
            self::SettingsManage,
        ];
    }

    /**
     * @return list<array{group: string, label: string, items: list<array{key: string, label: string}>}>
     */
    public static function catalog(): array
    {
        $groups = [];
        foreach (self::subAdminToggles() as $permission) {
            $groups[$permission->group()]['items'][] = [
                'key' => $permission->value,
                'label' => $permission->label(),
            ];
        }

        $labels = [
            'students' => 'Students',
            'teachers' => 'Teachers',
            'levels' => 'Levels & batches',
            'queries' => 'Queries',
            'requests' => 'Requests',
            'assessments' => 'Assessments',
            'settings' => 'Settings',
        ];

        $catalog = [];
        foreach ($groups as $key => $group) {
            $catalog[] = [
                'group' => $key,
                'label' => $labels[$key] ?? $key,
                'items' => $group['items'],
            ];
        }

        return $catalog;
    }
}
