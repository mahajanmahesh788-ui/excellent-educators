import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/auth/presentation/pages/admin_login_page_editor.dart';
import 'package:excellent_educators_web/features/schedule/presentation/pages/admin_google_meet_page.dart';
import 'package:excellent_educators_web/features/settings/data/dto/app_settings_dto.dart';
import 'package:excellent_educators_web/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved')));
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
      title: 'Settings',
      body: DefaultTabController(
        length: 3,
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
                Tab(text: 'Organisation'),
                Tab(text: 'Content'),
                Tab(text: 'Meet'),
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
            'Organisation settings',
            style: TextStyle(color: Brand.navy, fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const SizedBox(height: 4),
          const Text(
            'These apply across Excellent Educators. More options can be added here later.',
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
                    return 'Required';
                  }
                  if (item.type == 'integer') {
                    final parsed = int.tryParse(value.trim());
                    if (parsed == null) {
                      return 'Enter a whole number';
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
              child: Text(saving ? 'Saving…' : 'Save settings'),
            ),
          ),
        ],
      ),
    );
  }
}
