import 'dart:js_interop';

@JS('AudioContext')
external JSAny? get _audioContextCtor;

@JS()
extension type _AudioContext._(JSObject _) implements JSObject {
  external factory _AudioContext();
  external JSNumber get currentTime;
  external _AudioDestinationNode get destination;
  external _OscillatorNode createOscillator();
  external _GainNode createGain();
  external JSPromise<JSAny?> resume();
}

@JS()
extension type _AudioDestinationNode._(JSObject _) implements JSObject {}

@JS()
extension type _AudioParam._(JSObject _) implements JSObject {
  external void setValueAtTime(JSNumber value, JSNumber time);
  external void exponentialRampToValueAtTime(JSNumber value, JSNumber time);
}

@JS()
extension type _GainNode._(JSObject _) implements JSObject {
  external _AudioParam get gain;
  external void connect(_AudioDestinationNode destination);
}

@JS()
extension type _OscillatorNode._(JSObject _) implements JSObject {
  external set type(String value);
  external _AudioParam get frequency;
  external void connect(_GainNode destination);
  external void start([JSNumber when]);
  external void stop([JSNumber when]);
}

/// Soft in-app chime when a slide toast appears (not OS/browser notification sound).
_AudioContext? _sharedCtx;

void unlockNotificationAudio() {
  try {
    if (_audioContextCtor == null) return;
    _sharedCtx ??= _AudioContext();
    // ignore: discarded_futures
    _sharedCtx!.resume();
  } catch (_) {}
}

void playNotificationSound() {
  try {
    if (_audioContextCtor == null) return;
    final ctx = _sharedCtx ?? _AudioContext();
    _sharedCtx = ctx;
    // ignore: discarded_futures
    ctx.resume();
    final osc = ctx.createOscillator();
    final gain = ctx.createGain();
    osc.type = 'sine';
    final now = ctx.currentTime.toDartDouble;
    osc.frequency.setValueAtTime(880.toJS, now.toJS);
    gain.gain.setValueAtTime(0.0001.toJS, now.toJS);
    gain.gain.exponentialRampToValueAtTime(0.08.toJS, (now + 0.02).toJS);
    gain.gain.exponentialRampToValueAtTime(0.0001.toJS, (now + 0.28).toJS);
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start(now.toJS);
    osc.stop((now + 0.3).toJS);
  } catch (_) {
    // Autoplay policies / missing Web Audio — toast still shows silently.
  }
}
