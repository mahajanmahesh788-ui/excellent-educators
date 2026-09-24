import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/core/utils/display_date.dart';
import 'package:excellent_educators_web/core/widgets/app_confirm_dialog.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/academic_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/admin_list_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/directory_ui.dart';
import 'package:excellent_educators_web/features/auth/domain/admin_permission.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminSubAdminsPage extends ConsumerWidget {
  const AdminSubAdminsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(adminSubAdminsFilterProvider);
    final pageValue = ref.watch(adminSubAdminsProvider(filter));
    final repo = ref.watch(academicRepositoryProvider);
    final page = pageValue.asData?.value;

    return AppScaffold(
      title: AppStrings.subAdmins,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(RoutePaths.adminSubAdminNew),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.addSubAdmin),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DirectoryToolbar(
            searchHint: AppStrings.searchNamePhoneAddressOrEmail,
            searchQuery: filter.search,
            onSearchChanged: (value) {
              ref.read(adminSubAdminsFilterProvider.notifier).state =
                  filter.copyWith(search: value, page: 1);
            },
            total: page?.total,
            page: page?.page ?? filter.page,
            perPage: page?.perPage,
            onPageChanged: (nextPage) {
              ref.read(adminSubAdminsFilterProvider.notifier).state =
                  filter.copyWith(page: nextPage);
            },
          ),
          Expanded(
            child: AsyncBody(
              value: pageValue,
              onRetry: () => ref.invalidate(adminSubAdminsProvider(filter)),
              builder: (result) {
                final items = repo.parseSubAdmins(result);
                if (items.isEmpty) {
                  return const EmptyHint(
                    AppStrings.noSubAdminsYet,
                    icon: EmptyIcons.search,
                    subtitle:
                        AppStrings.createASubAdminLoginAndTurnOnPermissions,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 72),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final admin = items[index];
                    final enabled =
                        admin.permissions.values.where((on) => on).length;
                    final typeLabel =
                        admin.isAgent ? AppStrings.agent : 'Admin';
                    return Card(
                      child: ListTile(
                        title: Text(admin.name),
                        subtitle: Text(
                          '$typeLabel · ${admin.email} · ${admin.phone} · ${genderLabel(admin.gender)} · $enabled on',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _StatusTag(active: admin.isActive),
                            IconButton(
                              tooltip: AppStrings.history,
                              icon: const Icon(Icons.history),
                              onPressed: () => context.go(
                                RoutePaths.adminSubAdminHistoryFor(admin.id),
                              ),
                            ),
                          ],
                        ),
                        onTap: () =>
                            context.go(RoutePaths.adminSubAdminEditFor(admin.id)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AdminCreateSubAdminPage extends ConsumerWidget {
  const AdminCreateSubAdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _SubAdminFormPage();
  }
}

class AdminEditSubAdminPage extends ConsumerWidget {
  const AdminEditSubAdminPage({super.key, required this.subAdminId});

  final String subAdminId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SubAdminFormPage(subAdminId: subAdminId);
  }
}

class _SubAdminFormPage extends ConsumerStatefulWidget {
  const _SubAdminFormPage({this.subAdminId});

  final String? subAdminId;

  @override
  ConsumerState<_SubAdminFormPage> createState() => _SubAdminFormPageState();
}

class _SubAdminFormPageState extends ConsumerState<_SubAdminFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  String? _gender;
  var _type = 'admin';
  var _active = true;
  var _saving = false;
  final _toggles = <String, bool>{};
  String? _boundId;

  static const _agentKeys = {
    AdminPermission.studentsView,
    AdminPermission.studentsCreate,
  };

  bool get _editing => widget.subAdminId != null;
  bool get _isAgent => _type == 'agent';

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _bind(SubAdminDto admin) {
    if (_boundId == admin.id) {
      return;
    }
    _boundId = admin.id;
    _name.text = admin.name;
    _email.text = admin.email;
    _phone.text = admin.phone;
    _gender = admin.gender.isEmpty ? null : admin.gender;
    _type = admin.type;
    _active = admin.isActive;
    _toggles
      ..clear()
      ..addAll(admin.permissions);
  }

  void _setType(String type) {
    setState(() {
      _type = type;
      if (type == 'agent') {
        for (final key in _toggles.keys.toList()) {
          if (!_agentKeys.contains(key)) {
            _toggles[key] = false;
          }
        }
        _toggles[AdminPermission.studentsView] =
            _toggles[AdminPermission.studentsView] ?? true;
        _toggles[AdminPermission.studentsCreate] =
            _toggles[AdminPermission.studentsCreate] ?? true;
      }
    });
  }

  Future<void> _save(List<PermissionCatalogGroupDto> catalog) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    final permissions = <String, bool>{};
    for (final group in catalog) {
      for (final item in group.items) {
        if (_isAgent && !_agentKeys.contains(item.key)) {
          permissions[item.key] = false;
          continue;
        }
        permissions[item.key] = _toggles[item.key] == true;
      }
    }
    try {
      final repo = ref.read(academicRepositoryProvider);
      if (_editing) {
        await repo.updateSubAdmin(widget.subAdminId!, {
          'name': _name.text.trim(),
          'email': _email.text.trim(),
          'phone': _phone.text.trim(),
          'gender': _gender,
          'type': _type,
          'status': _active ? 'active' : 'inactive',
          if (_password.text.isNotEmpty) 'password': _password.text,
          'permissions': permissions,
        });
      } else {
        await repo.createSubAdmin({
          'name': _name.text.trim(),
          'email': _email.text.trim(),
          'password': _password.text,
          'phone': _phone.text.trim(),
          'gender': _gender,
          'type': _type,
          'permissions': permissions,
        });
      }
      ref.invalidate(adminSubAdminsProvider);
      if (mounted) {
        context.go(RoutePaths.adminSubAdmins);
      }
    } catch (error) {
      if (mounted) {
        showFailure(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: AppStrings.deleteSubAdmin,
      message: AppStrings.createASubAdminLoginAndTurnOnPermissions,
      confirmLabel: AppStrings.delete,
      cancelLabel: AppStrings.cancel,
      destructive: true,
    );
    if (confirmed != true || widget.subAdminId == null) {
      return;
    }
    try {
      await ref
          .read(academicRepositoryProvider)
          .deleteSubAdmin(widget.subAdminId!);
      ref.invalidate(adminSubAdminsProvider);
      if (mounted) {
        context.go(RoutePaths.adminSubAdmins);
      }
    } catch (error) {
      if (mounted) {
        showFailure(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(subAdminPermissionCatalogProvider);
    final existing = widget.subAdminId == null
        ? null
        : ref.watch(adminSubAdminProvider(widget.subAdminId!));

    return AppFormPage(
      title: _editing ? AppStrings.editSubAdmin : AppStrings.addSubAdmin,
      backTo: RoutePaths.adminSubAdmins,
      child: catalog.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Text(error.toString()),
        data: (groups) {
          if (existing != null) {
            return existing.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Text(error.toString()),
              data: (admin) {
                _bind(admin);
                return _form(groups);
              },
            );
          }
          return _form(groups);
        },
      ),
    );
  }

  Widget _form(List<PermissionCatalogGroupDto> groups) {
    final visibleGroups = _isAgent
        ? groups
            .map(
              (group) => PermissionCatalogGroupDto(
                group: group.group,
                label: group.label,
                items: group.items
                    .where((item) => _agentKeys.contains(item.key))
                    .toList(),
              ),
            )
            .where((group) => group.items.isNotEmpty)
            .toList()
        : groups;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: AppStrings.name),
            validator: (value) =>
                value == null || value.trim().isEmpty ? AppStrings.required : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _email,
            decoration: const InputDecoration(labelText: AppStrings.email),
            validator: (value) =>
                value == null || value.trim().isEmpty ? AppStrings.required : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _password,
            obscureText: true,
            decoration: InputDecoration(
              labelText: _editing ? AppStrings.password : AppStrings.password,
            ),
            validator: (value) {
              if (_editing) {
                return null;
              }
              return value == null || value.isEmpty ? AppStrings.required : null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phone,
            decoration: const InputDecoration(labelText: AppStrings.phone),
            validator: (value) =>
                value == null || value.trim().isEmpty ? AppStrings.required : null,
          ),
          const SizedBox(height: 12),
          GenderDropdown(
            value: _gender,
            onChanged: (value) => setState(() => _gender = value),
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.accountType,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'admin', label: Text('Admin')),
              ButtonSegment(value: 'agent', label: Text(AppStrings.agent)),
            ],
            selected: {_type},
            onSelectionChanged: (value) => _setType(value.first),
          ),
          if (_isAgent) ...[
            const SizedBox(height: 8),
            const Text(
              AppStrings.agentPermissionsHint,
              style: TextStyle(color: Brand.muted, fontSize: 13),
            ),
          ],
          if (_editing) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(AppStrings.active),
              value: _active,
              onChanged: (value) => setState(() => _active = value),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            AppStrings.permissions,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(AppStrings.permissionDefaultsOff),
          const SizedBox(height: 12),
          for (final group in visibleGroups) ...[
            Text(group.label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            for (final item in group.items)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.label),
                value: _toggles[item.key] == true,
                onChanged: (value) =>
                    setState(() => _toggles[item.key] = value),
              ),
            const SizedBox(height: 8),
          ],
          FilledButton(
            onPressed: _saving ? null : () => _save(groups),
            child: Text(_saving ? AppStrings.saving : AppStrings.save),
          ),
          if (_editing) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => context.go(
                RoutePaths.adminSubAdminHistoryFor(widget.subAdminId!),
              ),
              icon: const Icon(Icons.history),
              label: const Text(AppStrings.history),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _delete,
              child: const Text(AppStrings.deleteSubAdmin),
            ),
          ],
        ],
      ),
    );
  }
}

class AdminSubAdminHistoryPage extends ConsumerWidget {
  const AdminSubAdminHistoryPage({super.key, required this.subAdminId});

  final String subAdminId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admin = ref.watch(adminSubAdminProvider(subAdminId));
    final history = ref.watch(adminSubAdminHistoryProvider(subAdminId));

    return AppScaffold(
      title: AppStrings.subAdminHistory,
      backTo: RoutePaths.adminSubAdmins,
      body: ListView(
        children: [
          AsyncBody(
            value: admin,
            onRetry: () => ref.invalidate(adminSubAdminProvider(subAdminId)),
            builder: (item) {
              return DetailSection(
                title: item.name,
                children: [
                  DetailRow(
                    label: AppStrings.accountType,
                    value: item.isAgent ? AppStrings.agent : 'Admin',
                  ),
                  DetailRow(label: AppStrings.email, value: item.email),
                  DetailRow(label: AppStrings.phone, value: item.phone),
                  DetailRow(
                    label: AppStrings.status2,
                    value: item.isActive
                        ? AppStrings.active
                        : AppStrings.inactive,
                  ),
                  DetailRow(
                    label: AppStrings.studentsCreated,
                    value: '${item.studentsCreatedCount}',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          DetailSection(
            title: AppStrings.history,
            children: [
              AsyncBody(
                value: history,
                onRetry: () =>
                    ref.invalidate(adminSubAdminHistoryProvider(subAdminId)),
                builder: (items) {
                  final isAgent = admin.valueOrNull?.isAgent ?? false;
                  if (isAgent) {
                    if (items.isEmpty) {
                      return const Text(
                        AppStrings.noStudentsCreatedYet,
                        style: TextStyle(color: Brand.muted, fontSize: 13),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final item in items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              '${formatDisplayDate(item.occurredAt)}  ${item.studentName ?? item.message}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Brand.navyDeep,
                                fontSize: 14,
                              ),
                            ),
                          ),
                      ],
                    );
                  }

                  return ActivityTimeline(items: items);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final background =
        active ? const Color(0xFFE8F5E9) : const Color(0xFFF5F0E6);
    final border = active ? const Color(0xFF81C784) : const Color(0xFFE6DCCB);
    final color = active ? const Color(0xFF2E7D32) : Brand.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Text(
        active ? AppStrings.active : AppStrings.inactive,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
