import 'package:url_launcher/url_launcher.dart';

Future<bool> launchPhoneCall(String? phone) async {
  final digits = (phone ?? '').replaceAll(RegExp(r'\s+'), '');
  if (digits.isEmpty) {
    return false;
  }
  final uri = Uri(scheme: 'tel', path: digits);
  return launchUrl(uri);
}

Future<bool> launchExternalUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    return false;
  }
  return launchUrl(uri, webOnlyWindowName: '_blank');
}
