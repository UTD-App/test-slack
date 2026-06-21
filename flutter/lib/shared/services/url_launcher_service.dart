import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Centralized external-links gateway shared across the whole app.
///
/// Follows the base golden rule: packages ASK, the base EXECUTES. A feature
/// never imports `url_launcher` directly — it calls a method here to open a
/// browser, dial a number, send an email, or jump to WhatsApp, and gets back
/// a simple `bool` (whether the launch succeeded).
///
/// On Android 11+ the target schemes (`tel`, `mailto`, `https`) must be
/// declared in `AndroidManifest.xml` under `<queries>`, and on iOS under
/// `LSApplicationQueriesSchemes`, otherwise `canLaunchUrl` returns false.
class UrlLauncherService {
  UrlLauncherService._();
  static final UrlLauncherService instance = UrlLauncherService._();

  /// Opens [url] in the external browser (or in-app webview when
  /// [external] is false). Returns whether the launch succeeded.
  Future<bool> openUrl(String url, {bool external = true}) {
    return _launch(
      Uri.parse(url),
      mode: external
          ? LaunchMode.externalApplication
          : LaunchMode.inAppBrowserView,
    );
  }

  /// Opens the phone dialer pre-filled with [number] (`tel:`).
  Future<bool> dialPhone(String number) {
    return _launch(Uri(scheme: 'tel', path: _digits(number)));
  }

  /// Opens the mail composer to [to] with an optional [subject]/[body]
  /// (`mailto:`).
  Future<bool> sendEmail(String to, {String? subject, String? body}) {
    final query = <String, String>{
      if (subject != null) 'subject': subject,
      if (body != null) 'body': body,
    };
    return _launch(
      Uri(
        scheme: 'mailto',
        path: to,
        query: query.isEmpty ? null : _encodeQuery(query),
      ),
    );
  }

  /// Opens a WhatsApp chat with [phone] (digits only, with country code) and an
  /// optional pre-filled [message]. Uses the universal `wa.me` link so it works
  /// whether WhatsApp is installed or falls back to the browser.
  Future<bool> openWhatsApp(String phone, {String? message}) {
    final uri = Uri.https('wa.me', '/${_digits(phone)}', {
      if (message != null && message.isNotEmpty) 'text': message,
    });
    return _launch(uri, mode: LaunchMode.externalApplication);
  }

  /// Opens the default maps app at the given coordinates.
  Future<bool> openMaps(double latitude, double longitude) {
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': '$latitude,$longitude',
    });
    return _launch(uri, mode: LaunchMode.externalApplication);
  }

  Future<bool> _launch(
    Uri uri, {
    LaunchMode mode = LaunchMode.platformDefault,
  }) async {
    try {
      if (!await canLaunchUrl(uri)) return false;
      return launchUrl(uri, mode: mode);
    } catch (e) {
      debugPrint('UrlLauncherService failed for $uri: $e');
      return false;
    }
  }

  /// Strips everything except digits and a leading `+` from a phone number.
  String _digits(String input) =>
      input.replaceAll(RegExp(r'[^0-9+]'), '');

  String _encodeQuery(Map<String, String> params) => params.entries
      .map((e) =>
          '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
      .join('&');
}
