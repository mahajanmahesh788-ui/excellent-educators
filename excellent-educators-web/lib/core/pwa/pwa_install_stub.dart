/// Non-web stub — install is only available on Flutter web.
bool pwaIsStandalone() => false;

bool pwaIsIos() => false;

bool pwaCanInstall() => false;

void pwaOnAvailable(void Function() callback) {}

Future<String> pwaPromptInstall() async => 'unavailable';
