import 'package:excellent_educators_web/core/constants/app_strings.dart';
class DimensionDefinition {
  const DimensionDefinition({required this.code, required this.name});

  final String code;
  final String name;
}

abstract final class DimensionCatalog {
  static const values = <DimensionDefinition>[
    DimensionDefinition(code: 'P', name: AppStrings.personality),
    DimensionDefinition(code: 'I', name: AppStrings.interests),
    DimensionDefinition(code: AppStrings.cf, name: AppStrings.confidence),
    DimensionDefinition(code: 'L', name: AppStrings.leadership),
    DimensionDefinition(code: AppStrings.cm, name: AppStrings.communication),
    DimensionDefinition(code: AppStrings.dm, name: 'Decision-making'),
    DimensionDefinition(code: AppStrings.cr, name: AppStrings.creativity),
    DimensionDefinition(code: AppStrings.cu, name: AppStrings.curiosity),
    DimensionDefinition(code: AppStrings.tw, name: AppStrings.teamwork),
    DimensionDefinition(code: AppStrings.fa, name: AppStrings.futureAspirations),
  ];

  static const codes = ['P', 'I', AppStrings.cf, 'L', AppStrings.cm, AppStrings.dm, AppStrings.cr, AppStrings.cu, AppStrings.tw, AppStrings.fa];

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
