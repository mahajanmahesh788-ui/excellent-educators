import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/auth/data/dto/login_page_dtos.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/login_page_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminLoginPageEditor extends ConsumerStatefulWidget {
  const AdminLoginPageEditor({super.key});

  @override
  ConsumerState<AdminLoginPageEditor> createState() => _AdminLoginPageEditorState();
}

class _AdminLoginPageEditorState extends ConsumerState<AdminLoginPageEditor> {
  final _formKey = GlobalKey<FormState>();
  var _saving = false;
  var _initialized = false;

  late final _tagline = TextEditingController();
  late final _headline = TextEditingController();
  late final _description = TextEditingController();
  late final _missionQuote = TextEditingController();
  late final _formTitle = TextEditingController();
  late final _formSubtitle = TextEditingController();
  List<LoginPagePillarDto> _pillars = [];

  @override
  void dispose() {
    _tagline.dispose();
    _headline.dispose();
    _description.dispose();
    _missionQuote.dispose();
    _formTitle.dispose();
    _formSubtitle.dispose();
    for (final pillar in _pillarControllers) {
      pillar.title.dispose();
      pillar.body.dispose();
    }
    super.dispose();
  }

  final List<_PillarControllers> _pillarControllers = [];

  void _bind(LoginPageContentDto content) {
    if (_initialized) {
      return;
    }
    _initialized = true;
    _tagline.text = content.tagline;
    _headline.text = content.headline;
    _description.text = content.description;
    _missionQuote.text = content.missionQuote ?? '';
    _formTitle.text = content.formTitle;
    _formSubtitle.text = content.formSubtitle;
    _pillars = content.pillars;
    for (final pillar in _pillars) {
      _pillarControllers.add(_PillarControllers.fromPillar(pillar));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    try {
      final payload = LoginPageContentDto(
        tagline: _tagline.text.trim(),
        headline: _headline.text.trim(),
        description: _description.text.trim(),
        pillars: _pillarControllers
            .map(
              (pillar) => LoginPagePillarDto(
                icon: pillar.icon,
                title: pillar.title.text.trim(),
                body: pillar.body.text.trim(),
              ),
            )
            .toList(),
        missionQuote: _missionQuote.text.trim().isEmpty ? null : _missionQuote.text.trim(),
        formTitle: _formTitle.text.trim(),
        formSubtitle: _formSubtitle.text.trim(),
        forgotFormTitle: LoginPageContentDto.defaults.forgotFormTitle,
        forgotFormSubtitle: LoginPageContentDto.defaults.forgotFormSubtitle,
      );
      await ref.read(loginPageRepositoryProvider).updateAdmin(payload);
      ref.invalidate(adminLoginPageContentProvider);
      ref.invalidate(loginPageContentProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Content saved.')),
        );
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

  void _addPillar() {
    setState(() {
      _pillarControllers.add(_PillarControllers.fromPillar(const LoginPagePillarDto(
        icon: 'auto_awesome_outlined',
        title: '',
        body: '',
      )));
    });
  }

  void _removePillar(int index) {
    if (_pillarControllers.length <= 1) {
      return;
    }
    setState(() {
      _pillarControllers[index].title.dispose();
      _pillarControllers[index].body.dispose();
      _pillarControllers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = ref.watch(adminLoginPageContentProvider);

    return AppScaffold(
      title: 'Content',
      body: AsyncBody(
        value: content,
        onRetry: () => ref.invalidate(adminLoginPageContentProvider),
        builder: (data) {
          _bind(data);
          return Form(
            key: _formKey,
            child: ListView(
              children: [
                const Text(
                  'Brand panel',
                  style: TextStyle(color: Brand.navy, fontWeight: FontWeight.w700, fontSize: 18),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tagline,
                  decoration: const InputDecoration(labelText: 'Tagline'),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _headline,
                  decoration: const InputDecoration(
                    labelText: 'Headline',
                    helperText: 'Use Enter for a line break.',
                  ),
                  maxLines: 2,
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 4,
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _missionQuote,
                  decoration: const InputDecoration(labelText: 'Mission quote (desktop)'),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Philosophy cards',
                        style: TextStyle(color: Brand.navy, fontWeight: FontWeight.w700, fontSize: 18),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _pillarControllers.length >= 6 ? null : _addPillar,
                      icon: const Icon(Icons.add),
                      label: const Text('Add card'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < _pillarControllers.length; i++) ...[
                  _PillarEditor(
                    index: i,
                    controller: _pillarControllers[i],
                    onRemove: () => _removePillar(i),
                    canRemove: _pillarControllers.length > 1,
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 8),
                const Text(
                  'Sign-in form',
                  style: TextStyle(color: Brand.navy, fontWeight: FontWeight.w700, fontSize: 18),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _formTitle,
                  decoration: const InputDecoration(labelText: 'Login title'),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _formSubtitle,
                  decoration: const InputDecoration(labelText: 'Login subtitle'),
                  maxLines: 3,
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save changes'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PillarControllers {
  _PillarControllers({required this.icon, required this.title, required this.body});

  factory _PillarControllers.fromPillar(LoginPagePillarDto pillar) {
    return _PillarControllers(
      icon: pillar.icon,
      title: TextEditingController(text: pillar.title),
      body: TextEditingController(text: pillar.body),
    );
  }

  String icon;
  TextEditingController title;
  TextEditingController body;
}

class _PillarEditor extends StatefulWidget {
  const _PillarEditor({
    required this.index,
    required this.controller,
    required this.onRemove,
    required this.canRemove,
  });

  final int index;
  final _PillarControllers controller;
  final VoidCallback onRemove;
  final bool canRemove;

  @override
  State<_PillarEditor> createState() => _PillarEditorState();
}

class _PillarEditorState extends State<_PillarEditor> {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Card ${widget.index + 1}', style: const TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                if (widget.canRemove)
                  IconButton(
                    tooltip: 'Remove card',
                    onPressed: widget.onRemove,
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: widget.controller.icon,
              decoration: const InputDecoration(labelText: 'Icon'),
              items: loginPageIconOptions.keys
                  .map(
                    (key) => DropdownMenuItem(
                      value: key,
                      child: Row(
                        children: [
                          Icon(loginPageIcon(key), size: 18),
                          const SizedBox(width: 8),
                          Text(loginPageIconLabel(key)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => widget.controller.icon = value);
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: widget.controller.title,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: widget.controller.body,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
            ),
          ],
        ),
      ),
    );
  }
}
