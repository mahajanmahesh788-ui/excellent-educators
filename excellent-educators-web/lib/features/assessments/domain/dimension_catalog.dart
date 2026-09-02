class DimensionDefinition {
  const DimensionDefinition({required this.code, required this.name});

  final String code;
  final String name;
}

abstract final class DimensionCatalog {
  static const values = <DimensionDefinition>[
    DimensionDefinition(code: 'P', name: 'Personality'),
    DimensionDefinition(code: 'I', name: 'Interests'),
    DimensionDefinition(code: 'CF', name: 'Confidence'),
    DimensionDefinition(code: 'L', name: 'Leadership'),
    DimensionDefinition(code: 'CM', name: 'Communication'),
    DimensionDefinition(code: 'DM', name: 'Decision-making'),
    DimensionDefinition(code: 'CR', name: 'Creativity'),
    DimensionDefinition(code: 'CU', name: 'Curiosity'),
    DimensionDefinition(code: 'TW', name: 'Teamwork'),
    DimensionDefinition(code: 'FA', name: 'Future Aspirations'),
  ];

  static const codes = ['P', 'I', 'CF', 'L', 'CM', 'DM', 'CR', 'CU', 'TW', 'FA'];

  static String nameFor(String code) {
    for (final item in values) {
      if (item.code == code) {
        return item.name;
      }
    }
    return code;
  }

  static const maxCodesPerOption = 3;

  static bool isValid(String code) => codes.contains(code);

  static bool areValid(List<String> codes) {
    if (codes.isEmpty || codes.length > maxCodesPerOption) {
      return false;
    }
    final seen = <String>{};
    for (final code in codes) {
      if (!isValid(code) || seen.contains(code)) {
        return false;
      }
      seen.add(code);
    }
    return true;
  }
}
