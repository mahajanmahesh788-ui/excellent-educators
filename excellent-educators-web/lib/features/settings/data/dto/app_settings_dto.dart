class AppSettingsDto {
  const AppSettingsDto({
    required this.maxActiveStudents,
    required this.items,
  });

  factory AppSettingsDto.fromJson(Map<String, dynamic> json) {
    return AppSettingsDto(
      maxActiveStudents: (json['max_active_students'] as num?)?.toInt() ?? 50,
      items: (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => AppSettingItemDto.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  final int maxActiveStudents;
  final List<AppSettingItemDto> items;
}

class AppSettingItemDto {
  const AppSettingItemDto({
    required this.key,
    required this.group,
    required this.groupLabel,
    required this.label,
    required this.type,
    required this.value,
    this.help,
    this.min,
    this.max,
  });

  factory AppSettingItemDto.fromJson(Map<String, dynamic> json) {
    return AppSettingItemDto(
      key: json['key'] as String? ?? '',
      group: json['group'] as String? ?? 'general',
      groupLabel: json['group_label'] as String? ?? 'General',
      label: json['label'] as String? ?? '',
      type: json['type'] as String? ?? 'string',
      value: json['value'],
      help: json['help'] as String?,
      min: (json['min'] as num?)?.toInt(),
      max: (json['max'] as num?)?.toInt(),
    );
  }

  final String key;
  final String group;
  final String groupLabel;
  final String label;
  final String type;
  final Object? value;
  final String? help;
  final int? min;
  final int? max;
}
