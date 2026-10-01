import 'dart:typed_data';

import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/academic_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/mentor_profile_view.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const mentorTitleSuggestions = [
  'Student Mentor',
  'Faculty Mentor',
  'Student Growth Mentor',
];

const mentorGuidanceSuggestions = [
  'Goal Setting',
  'Strength Discovery',
  'Skill Development',
  'Confidence Building',
  'Future Planning',
  'Career Guidance',
  'Communication',
  'Personal Growth',
];

const mentorApproachSuggestions = [
  'Interactive',
  '1-on-1 Guidance',
  'Goal Oriented',
  'Practical Activities',
  'Student First',
];

class MentorProfileDraft {
  MentorProfileDraft({
    String? photoUrl,
    String? professionalTitle,
    String? bio,
    String? experienceSummary,
    List<String>? guidanceAreas,
    List<String>? mentoringApproach,
    List<MentorEducationDto>? education,
    List<MentorCertificationDto>? certifications,
    List<MentorExperienceDto>? experience,
  }) : photoUrl = TextEditingController(text: photoUrl ?? ''),
       professionalTitle = TextEditingController(text: professionalTitle ?? ''),
       bio = TextEditingController(text: bio ?? ''),
       experienceSummary = TextEditingController(text: experienceSummary ?? ''),
       guidanceAreas = List<String>.from(guidanceAreas ?? const []),
       mentoringApproach = List<String>.from(mentoringApproach ?? const []),
       education = List<MentorEducationDto>.from(education ?? const []),
       certifications = List<MentorCertificationDto>.from(
         certifications ?? const [],
       ),
       experience = List<MentorExperienceDto>.from(experience ?? const []);

  factory MentorProfileDraft.fromTeacher(TeacherDto teacher) {
    return MentorProfileDraft(
      photoUrl: teacher.photoUrl,
      professionalTitle: teacher.professionalTitle,
      bio: teacher.bio,
      experienceSummary: teacher.experienceSummary,
      guidanceAreas: teacher.guidanceAreas,
      mentoringApproach: teacher.mentoringApproach,
      education: teacher.education,
      certifications: teacher.certifications,
      experience: teacher.experience,
    );
  }

  final TextEditingController photoUrl;
  final TextEditingController professionalTitle;
  final TextEditingController bio;
  final TextEditingController experienceSummary;
  List<String> guidanceAreas;
  List<String> mentoringApproach;
  List<MentorEducationDto> education;
  List<MentorCertificationDto> certifications;
  List<MentorExperienceDto> experience;

  Map<String, dynamic> toPayload() {
    return {
      'photo_url': photoUrl.text.trim().isEmpty ? null : photoUrl.text.trim(),
      'professional_title': professionalTitle.text.trim().isEmpty
          ? null
          : professionalTitle.text.trim(),
      'bio': bio.text.trim().isEmpty ? null : bio.text.trim(),
      'experience_summary': experienceSummary.text.trim().isEmpty
          ? null
          : experienceSummary.text.trim(),
      'guidance_areas': guidanceAreas,
      'mentoring_approach': mentoringApproach,
      'education': education
          .where(
            (item) =>
                item.degree.trim().isNotEmpty &&
                item.institution.trim().isNotEmpty,
          )
          .map((item) => item.toJson())
          .toList(),
      'certifications': certifications
          .where((item) => item.name.trim().isNotEmpty)
          .map((item) => item.toJson())
          .toList(),
      'experience': experience
          .where(
            (item) =>
                item.organization.trim().isNotEmpty &&
                item.role.trim().isNotEmpty,
          )
          .map((item) => item.toJson())
          .toList(),
    };
  }

  void dispose() {
    photoUrl.dispose();
    professionalTitle.dispose();
    bio.dispose();
    experienceSummary.dispose();
  }
}

class MentorProfileEditor extends ConsumerStatefulWidget {
  const MentorProfileEditor({
    super.key,
    required this.draft,
    required this.onChanged,
    this.teacherId,
    this.asSelf = false,
  });

  final MentorProfileDraft draft;
  final VoidCallback onChanged;
  final String? teacherId;
  final bool asSelf;

  @override
  ConsumerState<MentorProfileEditor> createState() =>
      _MentorProfileEditorState();
}

class _MentorProfileEditorState extends ConsumerState<MentorProfileEditor> {
  Uint8List? _localPreview;
  var _uploading = false;

  MentorProfileDraft get draft => widget.draft;

  Future<void> _selectPhoto() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
    );
    if (files.isEmpty) {
      return;
    }
    final file = files.first;
    late final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (_) {
      if (mounted) {
        showFailure(context, 'Could not read the selected image.');
      }
      return;
    }
    if (bytes.isEmpty) {
      if (mounted) {
        showFailure(context, 'Could not read the selected image.');
      }
      return;
    }

    setState(() {
      _localPreview = bytes;
      _uploading = true;
    });

    try {
      final photoUrl = await ref
          .read(academicRepositoryProvider)
          .uploadTeacherPhoto(
            bytes: bytes,
            filename: file.name.isEmpty ? 'teacher-photo.jpg' : file.name,
            teacherId: widget.teacherId,
            asSelf: widget.asSelf,
          );
      if (photoUrl.isEmpty) {
        throw StateError('Upload did not return a photo URL.');
      }
      draft.photoUrl.text = photoUrl;
      widget.onChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo uploaded.')),
        );
      }
    } catch (error) {
      if (mounted) {
        showFailure(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  Future<void> _clearPhoto() async {
    draft.photoUrl.clear();
    setState(() => _localPreview = null);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EditorCard(
          icon: Icons.person_rounded,
          title: 'Professional identity',
          subtitle: 'This is the first impression students and parents see.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PhotoPreview(
                    url: draft.photoUrl.text,
                    bytes: _localPreview,
                    uploading: _uploading,
                    onTap: _uploading ? null : _selectPhoto,
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Profile photo',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Brand.navy,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Use a clear vertical portrait (JPG, PNG, or WebP). '
                          'Saved on the server under teacher photos.',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton.tonalIcon(
                              onPressed: _uploading ? null : _selectPhoto,
                              icon: _uploading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.photo_library_outlined),
                              label: Text(
                                _uploading ? 'Uploading…' : 'Select image',
                              ),
                            ),
                            if (draft.photoUrl.text.trim().isNotEmpty ||
                                _localPreview != null)
                              TextButton.icon(
                                onPressed: _uploading ? null : _clearPhoto,
                                icon: const Icon(Icons.delete_outline_rounded),
                                label: const Text('Remove'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: draft.professionalTitle,
                decoration: const InputDecoration(
                  labelText: 'Professional title',
                  hintText: 'Student Growth Mentor',
                  prefixIcon: Icon(Icons.badge_rounded),
                ),
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final title in mentorTitleSuggestions)
                    ActionChip(
                      avatar: const Icon(Icons.auto_awesome_rounded, size: 15),
                      label: Text(title),
                      onPressed: () {
                        draft.professionalTitle.text = title;
                        widget.onChanged();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: draft.bio,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Introduction / bio',
                  alignLabelWithHint: true,
                  hintText:
                      'Share how you help students discover strengths and build clear goals.',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 88),
                    child: Icon(Icons.format_quote_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: draft.experienceSummary,
                decoration: const InputDecoration(
                  labelText: 'Experience highlight',
                  hintText: '6+ Years Student Mentoring Experience',
                  prefixIcon: Icon(Icons.workspace_premium_rounded),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _EditorCard(
          icon: Icons.explore_rounded,
          title: 'Guidance & mentoring style',
          subtitle:
              'Highlight what students can learn and how you support them.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ChipSelector(
                title: 'Areas they guide',
                options: mentorGuidanceSuggestions,
                selected: draft.guidanceAreas,
                onToggle: (value) {
                  if (draft.guidanceAreas.contains(value)) {
                    draft.guidanceAreas = [...draft.guidanceAreas]
                      ..remove(value);
                  } else {
                    draft.guidanceAreas = [...draft.guidanceAreas, value];
                  }
                  widget.onChanged();
                },
              ),
              const SizedBox(height: 22),
              _ChipSelector(
                title: 'Mentoring approach',
                options: mentorApproachSuggestions,
                selected: draft.mentoringApproach,
                onToggle: (value) {
                  if (draft.mentoringApproach.contains(value)) {
                    draft.mentoringApproach = [...draft.mentoringApproach]
                      ..remove(value);
                  } else {
                    draft.mentoringApproach = [
                      ...draft.mentoringApproach,
                      value,
                    ];
                  }
                  widget.onChanged();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _EditorCard(
          icon: Icons.route_rounded,
          title: 'Professional journey',
          subtitle:
              'Add the credentials that build confidence in your guidance.',
          child: Column(
            children: [
              _SectionHeader(
                title: 'Education',
                actionLabel: 'Add education',
                onAction: () {
                  draft.education = [
                    ...draft.education,
                    const MentorEducationDto(degree: '', institution: ''),
                  ];
                  widget.onChanged();
                },
              ),
              for (var i = 0; i < draft.education.length; i++)
                _EducationEditor(
                  value: draft.education[i],
                  onChanged: (value) {
                    draft.education = [...draft.education]..[i] = value;
                    widget.onChanged();
                  },
                  onRemove: () {
                    draft.education = [...draft.education]..removeAt(i);
                    widget.onChanged();
                  },
                ),
              const SizedBox(height: 20),
              _SectionHeader(
                title: 'Certifications',
                actionLabel: 'Add certification',
                onAction: () {
                  draft.certifications = [
                    ...draft.certifications,
                    const MentorCertificationDto(name: ''),
                  ];
                  widget.onChanged();
                },
              ),
              for (var i = 0; i < draft.certifications.length; i++)
                _CertificationEditor(
                  value: draft.certifications[i],
                  onChanged: (value) {
                    draft.certifications = [...draft.certifications]
                      ..[i] = value;
                    widget.onChanged();
                  },
                  onRemove: () {
                    draft.certifications = [...draft.certifications]
                      ..removeAt(i);
                    widget.onChanged();
                  },
                ),
              const SizedBox(height: 20),
              _SectionHeader(
                title: 'Professional experience',
                actionLabel: 'Add experience',
                onAction: () {
                  draft.experience = [
                    ...draft.experience,
                    const MentorExperienceDto(organization: '', role: ''),
                  ];
                  widget.onChanged();
                },
              ),
              for (var i = 0; i < draft.experience.length; i++)
                _ExperienceEditor(
                  value: draft.experience[i],
                  onChanged: (value) {
                    draft.experience = [...draft.experience]..[i] = value;
                    widget.onChanged();
                  },
                  onRemove: () {
                    draft.experience = [...draft.experience]..removeAt(i);
                    widget.onChanged();
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EditorCard extends StatelessWidget {
  const _EditorCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7DDCD)),
        boxShadow: [
          BoxShadow(
            color: Brand.navy.withValues(alpha: .045),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDF3E8),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: const Color(0xFF1E7654)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SectionHeader(title: title, subtitle: subtitle),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({
    required this.url,
    this.bytes,
    this.uploading = false,
    this.onTap,
  });

  final String url;
  final Uint8List? bytes;
  final bool uploading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const width = 120.0;
    const height = 160.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          width: width + 8,
          height: height + 8,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Brand.gold, Color(0xFF1E7654)],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Stack(
              fit: StackFit.expand,
              children: [
                MentorAvatar(
                  name: 'Mentor',
                  photoUrl: url,
                  bytes: bytes,
                  width: width,
                  height: height,
                  borderRadius: 18,
                ),
                if (uploading)
                  ColoredBox(
                    color: Colors.black45,
                    child: const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                else
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      color: Colors.black54,
                      child: const Text(
                        'Change',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Brand.navy,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: const TextStyle(color: Brand.muted, fontSize: 13),
                ),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add, size: 16),
            label: Text(actionLabel!),
          ),
      ],
    );
  }
}

class _ChipSelector extends StatelessWidget {
  const _ChipSelector({
    required this.title,
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  final String title;
  final List<String> options;
  final List<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Brand.navy,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options)
              FilterChip(
                label: Text(option),
                selected: selected.contains(option),
                onSelected: (_) => onToggle(option),
                selectedColor: Brand.gold.withValues(alpha: 0.28),
                checkmarkColor: Brand.navy,
              ),
          ],
        ),
      ],
    );
  }
}

class _EducationEditor extends StatelessWidget {
  const _EducationEditor({
    required this.value,
    required this.onChanged,
    required this.onRemove,
  });

  final MentorEducationDto value;
  final ValueChanged<MentorEducationDto> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _EditableEntry(
      onRemove: onRemove,
      children: [
        TextFormField(
          initialValue: value.degree,
          decoration: const InputDecoration(labelText: 'Degree'),
          onChanged: (text) => onChanged(
            MentorEducationDto(
              degree: text,
              institution: value.institution,
              year: value.year,
            ),
          ),
        ),
        TextFormField(
          initialValue: value.institution,
          decoration: const InputDecoration(labelText: 'Institution'),
          onChanged: (text) => onChanged(
            MentorEducationDto(
              degree: value.degree,
              institution: text,
              year: value.year,
            ),
          ),
        ),
        TextFormField(
          initialValue: value.year ?? '',
          decoration: const InputDecoration(labelText: 'Year'),
          onChanged: (text) => onChanged(
            MentorEducationDto(
              degree: value.degree,
              institution: value.institution,
              year: text,
            ),
          ),
        ),
      ],
    );
  }
}

class _CertificationEditor extends StatelessWidget {
  const _CertificationEditor({
    required this.value,
    required this.onChanged,
    required this.onRemove,
  });

  final MentorCertificationDto value;
  final ValueChanged<MentorCertificationDto> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _EditableEntry(
      onRemove: onRemove,
      children: [
        TextFormField(
          initialValue: value.name,
          decoration: const InputDecoration(labelText: 'Certification'),
          onChanged: (text) => onChanged(
            MentorCertificationDto(
              name: text,
              organization: value.organization,
              year: value.year,
            ),
          ),
        ),
        TextFormField(
          initialValue: value.organization ?? '',
          decoration: const InputDecoration(labelText: 'Organization'),
          onChanged: (text) => onChanged(
            MentorCertificationDto(
              name: value.name,
              organization: text,
              year: value.year,
            ),
          ),
        ),
        TextFormField(
          initialValue: value.year ?? '',
          decoration: const InputDecoration(labelText: 'Year'),
          onChanged: (text) => onChanged(
            MentorCertificationDto(
              name: value.name,
              organization: value.organization,
              year: text,
            ),
          ),
        ),
      ],
    );
  }
}

class _ExperienceEditor extends StatelessWidget {
  const _ExperienceEditor({
    required this.value,
    required this.onChanged,
    required this.onRemove,
  });

  final MentorExperienceDto value;
  final ValueChanged<MentorExperienceDto> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _EditableEntry(
      onRemove: onRemove,
      children: [
        TextFormField(
          initialValue: value.organization,
          decoration: const InputDecoration(labelText: 'Organization'),
          onChanged: (text) => onChanged(
            MentorExperienceDto(
              organization: text,
              role: value.role,
              duration: value.duration,
            ),
          ),
        ),
        TextFormField(
          initialValue: value.role,
          decoration: const InputDecoration(labelText: 'Role'),
          onChanged: (text) => onChanged(
            MentorExperienceDto(
              organization: value.organization,
              role: text,
              duration: value.duration,
            ),
          ),
        ),
        TextFormField(
          initialValue: value.duration ?? '',
          decoration: const InputDecoration(labelText: 'Duration'),
          onChanged: (text) => onChanged(
            MentorExperienceDto(
              organization: value.organization,
              role: value.role,
              duration: text,
            ),
          ),
        ),
      ],
    );
  }
}

class _EditableEntry extends StatelessWidget {
  const _EditableEntry({required this.children, required this.onRemove});

  final List<Widget> children;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DECF)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final remove = IconButton(
            tooltip: 'Remove',
            onPressed: onRemove,
            color: const Color(0xFF9A3F3F),
            icon: const Icon(Icons.delete_outline_rounded),
          );
          if (constraints.maxWidth < 620) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(alignment: Alignment.centerRight, child: remove),
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  children[i],
                ],
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  flex: i == children.length - 1 ? 2 : 4,
                  child: children[i],
                ),
              ],
              const SizedBox(width: 4),
              remove,
            ],
          );
        },
      ),
    );
  }
}
