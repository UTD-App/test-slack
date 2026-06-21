import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:utd_app/localization/localization.dart';
import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/network/services/base_api_service.dart';
import 'package:utd_app/shared/core/color_manager.dart';
import 'package:utd_app/shared/widgets/gradient_background.dart';
import 'package:webview_flutter/webview_flutter.dart';

class _PageApi extends BaseApiService {
  Future<Result<Map<String, dynamic>>> fetch(String key) {
    return get<Map<String, dynamic>>(
      '/page/$key',
      fromJson: (body) {
        final data = body is Map ? body['data'] : body;
        return data is Map ? data.cast<String, dynamic>() : <String, dynamic>{};
      },
    );
  }
}

/// Generic static-content page (privacy policy, about us, …). Fetches
/// `/page/{key}` and renders the localized title (app bar) + body.
///
/// The body is authored as raw HTML in the dashboard (it may be a full HTML
/// document with its own CSS), so it is rendered inside a [WebView] — that's the
/// only renderer that honors arbitrary HTML + CSS exactly as written.
class ContentPage extends StatefulWidget {
  final String pageKey;
  const ContentPage({super.key, required this.pageKey});

  @override
  State<ContentPage> createState() => _ContentPageState();
}

class _ContentPageState extends State<ContentPage> {
  final _api = _PageApi();
  late final WebViewController _webController;
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _data = const {};

  @override
  void initState() {
    super.initState();
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(ColorManager.lumiaBgDark);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await _api.fetch(widget.pageKey);
    if (!mounted) return;
    res.when(
      success: (data) {
        _data = data;
        _webController.loadHtmlString(
          _document(_stripCodeFence(_localized(data['body']))),
        );
        setState(() => _loading = false);
      },
      failure: (msg, _) => setState(() {
        _loading = false;
        _error = msg;
      }),
    );
  }

  /// The server resolves title/body to the current locale and returns a plain
  /// string. A Map is still tolerated (older backend that returned all locales)
  /// so a staged rollout never breaks.
  String _localized(Object? value) {
    if (value is String) return value;
    if (value is! Map) return '';
    final lang = context.read<LocaleNotifier>().locale.languageCode;
    return (value[lang] ?? value['en'] ?? value['ar'] ?? '').toString();
  }

  /// Admin content is sometimes pasted wrapped in a Markdown code fence
  /// (```html … ```) — those fence markers would otherwise show as literal text
  /// above/below the page. Strip a leading ```/```lang line and a trailing ```.
  String _stripCodeFence(String input) {
    var s = input.trim();
    if (!s.startsWith('```')) return s;
    s = s.replaceFirst(RegExp(r'^`{3,}[^\n]*\n?'), '');
    s = s.replaceFirst(RegExp(r'`{3,}\s*$'), '');
    return s.trim();
  }

  /// Wrap the stored body so it renders well even when the admin saved only a
  /// fragment (no `<html>`/`<head>`): adds a UTF-8 + responsive viewport meta and
  /// a sane base style. A full document (starting with `<!doctype`/`<html`) is
  /// loaded as-is, so the author's own CSS wins.
  String _document(String body) {
    final trimmed = body.trimLeft().toLowerCase();
    if (trimmed.startsWith('<!doctype') || trimmed.startsWith('<html')) {
      return body;
    }
    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
  body { font-family: -apple-system, Roboto, Arial, sans-serif; line-height: 1.6;
         padding: 16px; margin: 0; word-wrap: break-word; }
  img { max-width: 100%; height: auto; }
</style>
</head>
<body>$body</body>
</html>''';
  }

  @override
  Widget build(BuildContext context) {
    final title = _localized(_data['title']);
    return Scaffold(
      backgroundColor: ColorManager.lumiaBgDark,
      appBar: AppBar(
        backgroundColor: ColorManager.lumiaBgDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: ColorManager.lumiaTextPrimary),
        title: Text(
          title,
          style: const TextStyle(
            color: ColorManager.lumiaTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Embedded WebViews swallow the pull-to-refresh gesture, so refreshing
          // the page is offered as an explicit app-bar action instead.
          IconButton(
            tooltip: context.tr('app.refresh'),
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh,
                color: ColorManager.lumiaTextPrimary),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return GradientBackground(
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off,
                    size: 48, color: ColorManager.lumiaTextSecondary),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(color: ColorManager.lumiaTextPrimary),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: ColorManager.lumiaAccent,
                  ),
                  onPressed: _load,
                  child: Text(context.tr('app.retry')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        WebViewWidget(controller: _webController),
        if (_loading)
          const Center(
            child:
                CircularProgressIndicator(color: ColorManager.lumiaAccentLight),
          ),
      ],
    );
  }
}
