import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Flipped when the API reports ACCOUNT_INACTIVE so auth can clear the session.
final accountInactiveSignalProvider = StateProvider<bool>((ref) => false);
