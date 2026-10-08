import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Flipped when an authenticated API call returns 401 (e.g. another login
/// revoked this token) so the UI can show a session-expired dialog.
final sessionExpiredSignalProvider = StateProvider<bool>((ref) => false);
