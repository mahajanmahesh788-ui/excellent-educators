import 'package:excellent_educators_web/app/theme/breakpoints.dart';
import 'package:flutter/material.dart';

class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({
    super.key,
    required this.child,
    this.maxWidth = 420,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width < Breakpoints.mobile ? 20.0 : 32.0;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: 32),
          child: child,
        ),
      ),
    );
  }
}
