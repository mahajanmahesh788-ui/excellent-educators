import 'package:excellent_educators_web/features/auth/domain/entities/app_user.dart';

abstract final class AdminPermission {
  static const studentsView = 'students.view';
  static const studentsCreate = 'students.create';
  static const studentsEdit = 'students.edit';
  static const studentsDelete = 'students.delete';
  static const studentsPromote = 'students.promote';
  static const studentsRating = 'students.rating';
  static const studentsMentor = 'students.mentor';

  static const teachersView = 'teachers.view';
  static const teachersCreate = 'teachers.create';
  static const teachersEdit = 'teachers.edit';
  static const teachersDelete = 'teachers.delete';
  static const teachersSchedule = 'teachers.schedule';
  static const teachersLeaves = 'teachers.leaves';

  static const levelsView = 'levels.view';
  static const levelsManage = 'levels.manage';

  static const queriesView = 'queries.view';
  static const queriesResolve = 'queries.resolve';

  static const requestsView = 'requests.view';
  static const requestsResolve = 'requests.resolve';

  static const assessmentsView = 'assessments.view';
  static const assessmentsManage = 'assessments.manage';

  static const settingsManage = 'settings.manage';
  static const subAdminsManage = 'sub_admins.manage';

  static bool canOpenPath(AppUser user, String location) {
    if (!location.startsWith('/admin')) {
      return true;
    }
    if (user.isAgent) {
      if (location.startsWith('/admin/notifications')) {
        return true;
      }
      if (location.startsWith('/admin/students')) {
        return user.canAnyAdmin(const [
          studentsView,
          studentsCreate,
          studentsEdit,
          studentsDelete,
          studentsPromote,
          studentsRating,
          studentsMentor,
        ]);
      }
      return false;
    }
    if (location == '/admin/dashboard' ||
        location.startsWith('/admin/best-') ||
        location.startsWith('/admin/notifications')) {
      return true;
    }
    if (location.startsWith('/admin/sub-admins')) {
      return user.canAdmin(subAdminsManage);
    }
    if (location.startsWith('/admin/students') && location.contains('/feedback')) {
      return user.canAdmin(studentsRating);
    }
    if (location.endsWith('/edit') && location.contains('/students/')) {
      return user.canAdmin(studentsEdit);
    }
    if (location.endsWith('/students/new')) {
      return user.canAdmin(studentsCreate);
    }
    if (location.startsWith('/admin/students')) {
      return user.canAnyAdmin(const [
        studentsView,
        studentsCreate,
        studentsEdit,
        studentsDelete,
        studentsPromote,
        studentsRating,
        studentsMentor,
      ]);
    }
    if (location.endsWith('/teachers/new')) {
      return user.canAdmin(teachersCreate);
    }
    if (location.contains('/teachers/') && location.endsWith('/edit')) {
      return user.canAdmin(teachersEdit);
    }
    if (location.startsWith('/admin/leaves')) {
      return user.canAnyAdmin(const [teachersLeaves, teachersSchedule]);
    }
    if (location.startsWith('/admin/schedule') || location.contains('/availability')) {
      return user.canAdmin(teachersSchedule);
    }
    if (location.startsWith('/admin/teachers')) {
      return user.canAnyAdmin(const [
        teachersView,
        teachersCreate,
        teachersEdit,
        teachersDelete,
        teachersSchedule,
        teachersLeaves,
      ]);
    }
    if (location.startsWith('/admin/attendance')) {
      return user.canAnyAdmin(const [queriesView, queriesResolve]);
    }
    if (location.startsWith('/admin/requests')) {
      return user.canAnyAdmin(const [requestsView, requestsResolve]);
    }
    if (location.startsWith('/admin/assessments')) {
      return user.canAnyAdmin(const [assessmentsView, assessmentsManage]);
    }
    if (location.startsWith('/admin/batches') || location.contains('/learning')) {
      return user.canAnyAdmin(const [levelsView, levelsManage]);
    }
    if (location.startsWith('/admin/settings') ||
        location.startsWith('/admin/login-page') ||
        location.startsWith('/admin/google-meet')) {
      return user.canAdmin(settingsManage);
    }
    return user.isFullAdmin;
  }
}
