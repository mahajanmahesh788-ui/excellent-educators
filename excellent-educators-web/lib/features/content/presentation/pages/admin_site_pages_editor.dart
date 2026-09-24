import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/content/data/dto/site_page_dto.dart';
import 'package:excellent_educators_web/features/content/presentation/providers/site_page_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminSitePagesEditor extends ConsumerStatefulWidget {
  const AdminSitePagesEditor({super.key});

  @override
  ConsumerState<AdminSitePagesEditor> createState() =>
      _AdminSitePagesEditorState();
}

class _AdminSitePagesEditorState extends ConsumerState<AdminSitePagesEditor> {
  final _titleControllers = <String, TextEditingController>{};
  final _bodyControllers = <String, TextEditingController>{};
  String? _selectedSlug;
  var _saving = false;
  var _bound = false;

  @override
  void dispose() {
    for (final controller in _titleControllers.values) {
      controller.dispose();
    }
    for (final controller in _bodyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _bind(List<SitePageDto> pages) {
    if (_bound) {
      return;
    }
    _bound = true;
    for (final page in pages) {
      _titleControllers[page.slug] = TextEditingController(text: page.title);
      _bodyControllers[page.slug] = TextEditingController(text: page.body);
    }
    _selectedSlug ??= pages.isEmpty ? null : pages.first.slug;
  }

  Future<void> _save() async {
    final slug = _selectedSlug;
    if (slug == null) {
      return;
    }
    final title = _titleControllers[slug]?.text.trim() ?? '';
    final body = _bodyControllers[slug]?.text.trim() ?? '';
    if (title.isEmpty || body.isEmpty) {
      showFailure(context, 'Title and body are required.');
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(sitePageRepositoryProvider).updateAdmin(
            slug,
            title: title,
            body: body,
          );
      ref.invalidate(adminSitePagesProvider);
      ref.invalidate(publicSitePageProvider(slug));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.pageContentSaved)),
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

  String _labelFor(String slug) {
    return switch (slug) {
      SitePageSlugs.privacy => AppStrings.privacyPolicy,
      SitePageSlugs.terms => AppStrings.termsAndConditions,
      SitePageSlugs.refund => AppStrings.refundPolicy,
      SitePageSlugs.contact => AppStrings.contactUs,
      _ => slug,
    };
  }

  @override
  Widget build(BuildContext context) {
    final pages = ref.watch(adminSitePagesProvider);

    return AsyncBody(
      value: pages,
      onRetry: () => ref.invalidate(adminSitePagesProvider),
      builder: (items) {
        _bind(items);
        final slug = _selectedSlug;
        if (slug == null || items.isEmpty) {
          return const EmptyHint(AppStrings.unableToLoadThisPage);
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Text(
              AppStrings.legalPages,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Brand.navy,
                  ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Edit Privacy Policy, Terms, Refund Policy, and Contact Us. These pages are public (no login).',
              style: TextStyle(color: Brand.muted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final page in items)
                  ChoiceChip(
                    label: Text(_labelFor(page.slug)),
                    selected: slug == page.slug,
                    onSelected: (_) => setState(() => _selectedSlug = page.slug),
                    selectedColor: Brand.navy,
                    labelStyle: TextStyle(
                      color: slug == page.slug ? Colors.white : Brand.navy,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleControllers[slug],
              decoration: const InputDecoration(
                labelText: 'Page title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _bodyControllers[slug],
              minLines: 16,
              maxLines: 28,
              decoration: const InputDecoration(
                labelText: 'Page content',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
                hintText: 'Use plain text. Separate sections with blank lines.',
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text(_saving ? AppStrings.saving : AppStrings.save),
              ),
            ),
          ],
        );
      },
    );
  }
}
