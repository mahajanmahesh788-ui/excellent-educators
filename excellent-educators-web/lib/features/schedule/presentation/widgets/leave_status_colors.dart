import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

Color leaveStatusForeground(String status) {
  return switch (status) {
    'pending' => const Color(0xFF785500),
    'reassignment_pending' => const Color(0xFF9A3412),
    'approved' => const Color(0xFF047857),
    'rejected' => const Color(0xFFB91C1C),
    'cancelled' => const Color(0xFF64748B),
    _ => Brand.muted,
  };
}

Color leaveStatusBackground(String status) {
  return switch (status) {
    'pending' => const Color(0xFFFFF7E8),
    'reassignment_pending' => const Color(0xFFFFF1E8),
    'approved' => const Color(0xFFECFDF5),
    'rejected' => const Color(0xFFFEF2F2),
    'cancelled' => const Color(0xFFF1F5F9),
    _ => const Color(0xFFF8FAFC),
  };
}
