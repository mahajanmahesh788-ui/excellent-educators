import 'dart:js_interop';

@JS('eePwaCanInstall')
external bool _eePwaCanInstall();

@JS('eePwaIsStandalone')
external bool _eePwaIsStandalone();

@JS('eePwaIsIos')
external bool _eePwaIsIos();

@JS('eePwaInstall')
external JSPromise<JSObject?> _eePwaInstall();

@JS('eePwaOnAvailable')
external void _eePwaOnAvailable(JSFunction callback);

@JS()
extension type _InstallChoice._(JSObject _) implements JSObject {
  external String get outcome;
}

bool pwaIsStandalone() {
  try {
    return _eePwaIsStandalone();
  } catch (_) {
    return false;
  }
}

bool pwaIsIos() {
  try {
    return _eePwaIsIos();
  } catch (_) {
    return false;
  }
}

bool pwaCanInstall() {
  try {
    return _eePwaCanInstall();
  } catch (_) {
    return false;
  }
}

void pwaOnAvailable(void Function() callback) {
  try {
    _eePwaOnAvailable(callback.toJS);
  } catch (_) {}
}

Future<String> pwaPromptInstall() async {
  try {
    final result = await _eePwaInstall().toDart;
    if (result == null) return 'unavailable';
    return _InstallChoice._(result).outcome;
  } catch (_) {
    return 'unavailable';
  }
}
