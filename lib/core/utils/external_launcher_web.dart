import 'dart:js_interop';

@JS('window.open')
external JSAny? _windowOpen(JSString url, JSString target);

Future<bool> openExternalUrlImpl(String url) async {
  try {
    _windowOpen(url.toJS, '_blank'.toJS);
    return true;
  } catch (_) {
    return false;
  }
}
