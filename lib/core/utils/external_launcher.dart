import 'external_launcher_stub.dart'
    if (dart.library.js_interop) 'external_launcher_web.dart';

Future<bool> openExternalUrl(String url) => openExternalUrlImpl(url);
