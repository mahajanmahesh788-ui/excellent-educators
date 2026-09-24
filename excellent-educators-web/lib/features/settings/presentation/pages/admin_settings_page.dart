import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/auth/presentation/pages/admin_login_page_editor.dart';
import 'package:excellent_educators_web/features/content/presentation/pages/admin_site_pages_editor.dart';
import 'package:excellent_educators_web/features/schedule/presentation/pages/admin_google_meet_page.dart';
import 'package:excellent_educators_web/features/settings/data/dto/app_settings_dto.dart';
import 'package:excellent_educators_web/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

class AdminSettingsPage extends ConsumerStatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  ConsumerState<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends ConsumerState<AdminSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  var _saving = false;
  var _bound = false;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _bind(AppSettingsDto data) {
    if (_bound) {
      return;
    }
    _bound = true;
    for (final item in data.items) {
      _controllers[item.key] = TextEditingController(text: '${item.value ?? ''}');
    }
  }

  Future<void> _save(AppSettingsDto data) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    try {
      final values = <String, Object?>{};
      for (final item in data.items) {
        final raw = _controllers[item.key]?.text.trim() ?? '';
        values[item.key] = item.type == 'integer' ? int.parse(raw) : raw;
      }
      await ref.read(settingsRepositoryProvider).save(values);
      ref.invalidate(adminSettingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.settingsSaved)));
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

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(adminSettingsProvider);

    return AppScaffold(
      title: AppStrings.settings,
      body: DefaultTabController(
        length: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: Brand.navy,
              unselectedLabelColor: Brand.muted,
              indicatorColor: Brand.gold,
              tabs: [
                Tab(text: AppStrings.organisation),
                Tab(text: AppStrings.content),
                Tab(text: AppStrings.legalPages),
                Tab(text: AppStrings.meet),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                children: [
                  AsyncBody(
                    value: settings,
                    onRetry: () => ref.invalidate(adminSettingsProvider),
                    builder: (data) {
                      _bind(data);
                      return _OrganisationSettingsForm(
                        formKey: _formKey,
                        data: data,
                        controllers: _controllers,
                        saving: _saving,
                        onSave: () => _save(data),
                      );
                    },
                  ),
                  const AdminLoginPageEditor(embedded: true),
                  const AdminSitePagesEditor(),
                  const AdminGoogleMeetConnectPanel(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrganisationSettingsForm extends StatelessWidget {
  const _OrganisationSettingsForm({
    required this.formKey,
    required this.data,
    required this.controllers,
    required this.saving,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final AppSettingsDto data;
  final Map<String, TextEditingController> controllers;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<AppSettingItemDto>>{};
    for (final item in data.items) {
      groups.putIfAbsent(item.groupLabel, () => []).add(item);
    }

    return Form(
      key: formKey,
      child: ListView(
        children: [
          const Text(
            AppStrings.organisationSettings,
            style: TextStyle(color: Brand.navy, fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const SizedBox(height: 4),
          const Text(
            AppStrings.theseApplyAcrossExcellentEducatorsMoreOptionsCanBeAdded,
            style: TextStyle(color: Brand.muted, height: 1.4),
          ),
          const SizedBox(height: 20),
          for (final entry in groups.entries) ...[
            Text(
              entry.key,
              style: const TextStyle(color: Brand.navy, fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 10),
            for (final item in entry.value) ...[
              TextFormField(
                controller: controllers[item.key],
                keyboardType: item.type == 'integer' ? TextInputType.number : TextInputType.text,
                inputFormatters: item.type == 'integer'
                    ? [FilteringTextInputFormatter.digitsOnly]
                    : const [],
                decoration: InputDecoration(
                  labelText: item.label,
                  helperText: item.help,
                  helperMaxLines: 3,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppStrings.required;
                  }
                  if (item.type == 'integer') {
                    final parsed = int.tryParse(value.trim());
                    if (parsed == null) {
                      return AppStrings.enterAWholeNumber;
                    }
                    if (item.min != null && parsed < item.min!) {
                      return 'Minimum is ${item.min}';
                    }
                    if (item.max != null && parsed > item.max!) {
                      return 'Maximum is ${item.max}';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: saving ? null : onSave,
              child: Text(saving ? AppStrings.saving : AppStrings.saveSettings),
            ),
          ),
        ],
      ),
    );
  }
}
