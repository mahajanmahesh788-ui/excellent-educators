import 'package:excellent_educators_web/core/storage/in_memory_token_store.dart';
import 'package:excellent_educators_web/core/storage/token_store.dart';

/// Non-web fallback (tests / VM). Prefer session storage on real browsers.
TokenStore createWebSessionTokenStore() => InMemoryTokenStore();
