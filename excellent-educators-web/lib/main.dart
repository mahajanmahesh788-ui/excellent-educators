import 'package:excellent_educators_web/app/app.dart';
import 'package:excellent_educators_web/app/bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  final overrides = await bootstrap();
  runApp(
    ProviderScope(
      overrides: overrides,
      child: const ExcellentEducatorsApp(),
    ),
  );
}
