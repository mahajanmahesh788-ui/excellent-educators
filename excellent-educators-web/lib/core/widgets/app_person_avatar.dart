import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Shared person avatar: network photo when present, otherwise initials.
class AppPersonAvatar extends StatelessWidget {
  const AppPersonAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.radius = 18,
    this.backgroundColor = Brand.navy,
    this.foregroundColor = Brand.gold,
    this.fontWeight = FontWeight.w700,
    this.maxInitials = 2,
  });

  final String name;
  final String? photoUrl;
  final double radius;
  final Color backgroundColor;
  final Color foregroundColor;
  final FontWeight fontWeight;

  /// 1 = first letter only; 2 = up to two word initials.
  final int maxInitials;

  static String initialsFor(String name, {int maxInitials = 2}) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '?';
    }
    if (maxInitials <= 1 || parts.length == 1) {
      return parts.first[0].toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final url = photoUrl?.trim();
    final hasPhoto = url != null && url.isNotEmpty;
    final initials = initialsFor(name, maxInitials: maxInitials);

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: hasPhoto ? NetworkImage(url) : null,
      child: hasPhoto
          ? null
          : Text(
              initials,
              style: TextStyle(
                color: foregroundColor,
                fontWeight: fontWeight,
                fontSize: radius * 0.72,
              ),
            ),
    );
  }
}
