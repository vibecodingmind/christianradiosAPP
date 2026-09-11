import 'package:url_launcher/url_launcher.dart';
import '../api/api_client.dart';

Uri? resolveAppUri(String? raw) {
  if (raw == null) return null;
  final value = raw.trim();
  if (value.isEmpty) return null;
  final parsed = Uri.tryParse(value);
  if (parsed == null) return null;
  if (parsed.hasScheme) return parsed;
  if (value.startsWith('/')) {
    return Uri.parse('$kWebOrigin$value');
  }
  return Uri.tryParse('https://$value');
}

Future<bool> openExternalLink(String? raw) async {
  final uri = resolveAppUri(raw);
  if (uri == null) return false;
  if (await canLaunchUrl(uri)) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
  return launchUrl(uri, mode: LaunchMode.platformDefault);
}
