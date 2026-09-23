import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/auth/data/dto/login_page_dtos.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/login_page_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

class AdminLoginPageEditor extends ConsumerStatefulWidget {
  const AdminLoginPageEditor({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<AdminLoginPageEditor> createState() =>
      _AdminLoginPageEditorState();
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
  late final _testimonialsHeading = TextEditingController();
  late final _whyHeading = TextEditingController();
  final List<_PillarControllers> _pillarControllers = [];
  final List<_TrustControllers> _trustControllers = [];
  final List<_StoryControllers> _storyControllers = [];
  final List<_TestimonialControllers> _testimonialControllers = [];

  @override
  void dispose() {
    _tagline.dispose();
    _headline.dispose();
    _description.dispose();
    _missionQuote.dispose();
    _formTitle.dispose();
    _formSubtitle.dispose();
    _testimonialsHeading.dispose();
    _whyHeading.dispose();
    for (final pillar in _pillarControllers) {
      pillar.dispose();
    }
    for (final trust in _trustControllers) {
      trust.dispose();
    }
    for (final story in _storyControllers) {
      story.dispose();
    }
    for (final item in _testimonialControllers) {
      item.dispose();
    }
    super.dispose();
  }

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
    _testimonialsHeading.text = content.testimonialsHeading ?? '';
    _whyHeading.text = content.whyHeading ?? '';
    for (final pillar in content.pillars) {
      _pillarControllers.add(_PillarControllers.fromPillar(pillar));
    }
    for (final signal in content.trustSignals) {
      _trustControllers.add(_TrustControllers.fromSignal(signal));
    }
    for (final story in content.stories) {
      _storyControllers.add(_StoryControllers.fromStory(story));
    }
    for (final item in content.testimonials) {
      _testimonialControllers.add(_TestimonialControllers.fromItem(item));
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
        trustSignals: _trustControllers
            .map(
              (item) => LoginPageTrustSignalDto(
                icon: item.icon,
                value: item.value.text.trim(),
                label: item.label.text.trim(),
              ),
            )
            .toList(),
        whyHeading: _whyHeading.text.trim().isEmpty
            ? null
            : _whyHeading.text.trim(),
        stories: _storyControllers
            .map(
              (item) => LoginPageStoryDto(
                title: item.title.text.trim(),
                body: item.body.text.trim(),
                imageUrl: item.imageUrl.text.trim(),
                imageOnLeft: item.imageOnLeft,
              ),
            )
            .toList(),
        testimonialsHeading: _testimonialsHeading.text.trim().isEmpty
            ? null
            : _testimonialsHeading.text.trim(),
        testimonials: _testimonialControllers
            .map(
              (item) => LoginPageTestimonialDto(
                quote: item.quote.text.trim(),
                attribution: item.attribution.text.trim(),
                role: item.role.text.trim().isEmpty
                    ? null
                    : item.role.text.trim(),
              ),
            )
            .toList(),
        missionQuote: _missionQuote.text.trim().isEmpty
            ? null
            : _missionQuote.text.trim(),
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
          const SnackBar(content: Text(AppStrings.contentSaved)),
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
      _pillarControllers.add(
        _PillarControllers.fromPillar(
          const LoginPagePillarDto(
            icon: 'auto_awesome_outlined',
            title: '',
            body: '',
          ),
        ),
      );
    });
  }

  void _removePillar(int index) {
    if (_pillarControllers.length <= 1) {
      return;
    }
    setState(() {
      _pillarControllers[index].dispose();
      _pillarControllers.removeAt(index);
    });
  }

  void _addTrust() {
    setState(() {
      _trustControllers.add(
        _TrustControllers.fromSignal(
          const LoginPageTrustSignalDto(
            icon: 'verified_outlined',
            value: '',
            label: '',
          ),
        ),
      );
    });
  }

  void _removeTrust(int index) {
    setState(() {
      _trustControllers[index].dispose();
      _trustControllers.removeAt(index);
    });
  }

  void _addStory() {
    setState(() {
      _storyControllers.add(
        _StoryControllers.fromStory(
          const LoginPageStoryDto(
            title: '',
            body: '',
            imageUrl: '',
          ),
        ),
      );
    });
  }

  void _removeStory(int index) {
    setState(() {
      _storyControllers[index].dispose();
      _storyControllers.removeAt(index);
    });
  }

  void _addTestimonial() {
    setState(() {
      _testimonialControllers.add(
        _TestimonialControllers.fromItem(
          const LoginPageTestimonialDto(
            quote: '',
            attribution: '',
          ),
        ),
      );
    });
  }

  void _removeTestimonial(int index) {
    setState(() {
      _testimonialControllers[index].dispose();
      _testimonialControllers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = ref.watch(adminLoginPageContentProvider);

    final editor = AsyncBody(
      value: content,
      onRetry: () => ref.invalidate(adminLoginPageContentProvider),
      builder: (data) {
        _bind(data);
        return Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                AppStrings.brandPanel,
                style: TextStyle(
                  color: Brand.navy,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tagline,
                decoration: const InputDecoration(labelText: AppStrings.tagline),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? AppStrings.required
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _headline,
                decoration: const InputDecoration(
                  labelText: AppStrings.headline,
                  helperText: AppStrings.useEnterForALineBreak,
                ),
                maxLines: 2,
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? AppStrings.required
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                decoration:
                    const InputDecoration(labelText: AppStrings.description),
                maxLines: 4,
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? AppStrings.required
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _missionQuote,
                decoration: const InputDecoration(
                  labelText: AppStrings.missionQuoteDesktop,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Trust signals',
                      style: TextStyle(
                        color: Brand.navy,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed:
                        _trustControllers.length >= 4 ? null : _addTrust,
                    icon: const Icon(Icons.add),
                    label: const Text('Add signal'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Shown as compact proof cards on the login page (max 4).',
                style: TextStyle(color: Brand.muted, fontSize: 12.5),
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < _trustControllers.length; i++) ...[
                _TrustEditor(
                  index: i,
                  controller: _trustControllers[i],
                  onRemove: () => _removeTrust(i),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Why it works',
                      style: TextStyle(
                        color: Brand.navy,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed:
                        _pillarControllers.length >= 6 ? null : _addPillar,
                    icon: const Icon(Icons.add),
                    label: const Text(AppStrings.addCard),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _whyHeading,
                decoration: const InputDecoration(
                  labelText: 'Why section heading',
                ),
              ),
              const SizedBox(height: 12),
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
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Photo stories',
                      style: TextStyle(
                        color: Brand.navy,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed:
                        _storyControllers.length >= 4 ? null : _addStory,
                    icon: const Icon(Icons.add),
                    label: const Text('Add story'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Photo + text rows on the public login page. Paste an image URL.',
                style: TextStyle(color: Brand.muted, fontSize: 12.5),
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < _storyControllers.length; i++) ...[
                _StoryEditor(
                  index: i,
                  controller: _storyControllers[i],
                  onRemove: () => _removeStory(i),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Testimonials',
                      style: TextStyle(
                        color: Brand.navy,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _testimonialControllers.length >= 6
                        ? null
                        : _addTestimonial,
                    icon: const Icon(Icons.add),
                    label: const Text('Add quote'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _testimonialsHeading,
                decoration: const InputDecoration(
                  labelText: 'Testimonials heading',
                ),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < _testimonialControllers.length; i++) ...[
                _TestimonialEditor(
                  index: i,
                  controller: _testimonialControllers[i],
                  onRemove: () => _removeTestimonial(i),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
              const Text(
                AppStrings.signInForm,
                style: TextStyle(
                  color: Brand.navy,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _formTitle,
                decoration:
                    const InputDecoration(labelText: AppStrings.loginTitle),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? AppStrings.required
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _formSubtitle,
                decoration:
                    const InputDecoration(labelText: AppStrings.loginSubtitle),
                maxLines: 3,
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? AppStrings.required
                        : null,
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
                    : const Text(AppStrings.saveChanges),
              ),
            ],
          ),
        );
      },
    );

    if (widget.embedded) {
      return editor;
    }

    return AppScaffold(
      title: AppStrings.content,
      body: editor,
    );
  }
}

class _PillarControllers {
  _PillarControllers({
    required this.icon,
    required this.title,
    required this.body,
  });

  factory _PillarControllers.fromPillar(LoginPagePillarDto pillar) {
    return _PillarControllers(
      icon: pillar.icon,
      title: TextEditingController(text: pillar.title),
      body: TextEditingController(text: pillar.body),
    );
  }

  String icon;
  final TextEditingController title;
  final TextEditingController body;

  void dispose() {
    title.dispose();
    body.dispose();
  }
}

class _TrustControllers {
  _TrustControllers({
    required this.icon,
    required this.value,
    required this.label,
  });

  factory _TrustControllers.fromSignal(LoginPageTrustSignalDto signal) {
    return _TrustControllers(
      icon: signal.icon,
      value: TextEditingController(text: signal.value),
      label: TextEditingController(text: signal.label),
    );
  }

  String icon;
  final TextEditingController value;
  final TextEditingController label;

  void dispose() {
    value.dispose();
    label.dispose();
  }
}

class _StoryControllers {
  _StoryControllers({
    required this.title,
    required this.body,
    required this.imageUrl,
    required this.imageOnLeft,
  });

  factory _StoryControllers.fromStory(LoginPageStoryDto story) {
    return _StoryControllers(
      title: TextEditingController(text: story.title),
      body: TextEditingController(text: story.body),
      imageUrl: TextEditingController(text: story.imageUrl),
      imageOnLeft: story.imageOnLeft,
    );
  }

  final TextEditingController title;
  final TextEditingController body;
  final TextEditingController imageUrl;
  bool imageOnLeft;

  void dispose() {
    title.dispose();
    body.dispose();
    imageUrl.dispose();
  }
}

class _TestimonialControllers {
  _TestimonialControllers({
    required this.quote,
    required this.attribution,
    required this.role,
  });

  factory _TestimonialControllers.fromItem(LoginPageTestimonialDto item) {
    return _TestimonialControllers(
      quote: TextEditingController(text: item.quote),
      attribution: TextEditingController(text: item.attribution),
      role: TextEditingController(text: item.role ?? ''),
    );
  }

  final TextEditingController quote;
  final TextEditingController attribution;
  final TextEditingController role;

  void dispose() {
    quote.dispose();
    attribution.dispose();
    role.dispose();
  }
}

class _IconDropdown extends StatelessWidget {
  const _IconDropdown({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: const InputDecoration(labelText: AppStrings.icon),
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
      onChanged: (next) {
        if (next != null) {
          onChanged(next);
        }
      },
    );
  }
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
                Text(
                  'Card ${widget.index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                if (widget.canRemove)
                  IconButton(
                    tooltip: AppStrings.removeCard,
                    onPressed: widget.onRemove,
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _IconDropdown(
              value: widget.controller.icon,
              onChanged: (value) =>
                  setState(() => widget.controller.icon = value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: widget.controller.title,
              decoration: const InputDecoration(labelText: AppStrings.title),
              validator: (value) =>
                  (value == null || value.trim().isEmpty)
                      ? AppStrings.required
                      : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: widget.controller.body,
              decoration:
                  const InputDecoration(labelText: AppStrings.description),
              maxLines: 3,
              validator: (value) =>
                  (value == null || value.trim().isEmpty)
                      ? AppStrings.required
                      : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustEditor extends StatefulWidget {
  const _TrustEditor({
    required this.index,
    required this.controller,
    required this.onRemove,
  });

  final int index;
  final _TrustControllers controller;
  final VoidCallback onRemove;

  @override
  State<_TrustEditor> createState() => _TrustEditorState();
}

class _TrustEditorState extends State<_TrustEditor> {
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
                Text(
                  'Signal ${widget.index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Remove signal',
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _IconDropdown(
              value: widget.controller.icon,
              onChanged: (value) =>
                  setState(() => widget.controller.icon = value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: widget.controller.value,
              decoration: const InputDecoration(
                labelText: 'Highlight value',
                helperText: 'Example: Mentor-led, Weekly, 1:1',
              ),
              validator: (value) =>
                  (value == null || value.trim().isEmpty)
                      ? AppStrings.required
                      : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: widget.controller.label,
              decoration: const InputDecoration(
                labelText: 'Supporting label',
              ),
              validator: (value) =>
                  (value == null || value.trim().isEmpty)
                      ? AppStrings.required
                      : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _TestimonialEditor extends StatelessWidget {
  const _TestimonialEditor({
    required this.index,
    required this.controller,
    required this.onRemove,
  });

  final int index;
  final _TestimonialControllers controller;
  final VoidCallback onRemove;

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
                Text(
                  'Quote ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Remove quote',
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller.quote,
              decoration: const InputDecoration(labelText: 'Quote'),
              maxLines: 3,
              validator: (value) =>
                  (value == null || value.trim().isEmpty)
                      ? AppStrings.required
                      : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controller.attribution,
              decoration: const InputDecoration(labelText: 'Name / attribution'),
              validator: (value) =>
                  (value == null || value.trim().isEmpty)
                      ? AppStrings.required
                      : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controller.role,
              decoration: const InputDecoration(
                labelText: 'Role (optional)',
                helperText: 'Student, Parent, Teacher…',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryEditor extends StatefulWidget {
  const _StoryEditor({
    required this.index,
    required this.controller,
    required this.onRemove,
  });

  final int index;
  final _StoryControllers controller;
  final VoidCallback onRemove;

  @override
  State<_StoryEditor> createState() => _StoryEditorState();
}

class _StoryEditorState extends State<_StoryEditor> {
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
                Text(
                  'Story ${widget.index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Remove story',
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: widget.controller.title,
              decoration: const InputDecoration(labelText: AppStrings.title),
              validator: (value) =>
                  (value == null || value.trim().isEmpty)
                      ? AppStrings.required
                      : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: widget.controller.body,
              decoration:
                  const InputDecoration(labelText: AppStrings.description),
              maxLines: 4,
              validator: (value) =>
                  (value == null || value.trim().isEmpty)
                      ? AppStrings.required
                      : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: widget.controller.imageUrl,
              decoration: const InputDecoration(
                labelText: 'Image URL',
                helperText: 'https://…',
              ),
              validator: (value) =>
                  (value == null || value.trim().isEmpty)
                      ? AppStrings.required
                      : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Photo on the left'),
              value: widget.controller.imageOnLeft,
              onChanged: (value) {
                setState(() => widget.controller.imageOnLeft = value);
              },
            ),
          ],
        ),
      ),
    );
  }
}
