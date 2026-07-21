// yivi_core exposes its theme and shared widgets only under lib/src (no public
// barrel), so the Yivi chrome here must import them by their src path.
// ignore_for_file: implementation_imports
import "package:flutter/material.dart";
import "package:webview_flutter/webview_flutter.dart";
import "package:webview_flutter_android/webview_flutter_android.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/irma_app_bar.dart";
import "package:yivi_core/src/widgets/loading_indicator.dart";
import "package:yivi_core/src/widgets/translated_text.dart";

import "face_liveness_message.dart";

/// Full-screen route that loads the Yivi-hosted Regula capture page in an
/// embedded WebView and resolves with a [FaceCaptureMessage].
///
/// This is the FOSS liveness surface for the F-Droid flavor: the APK ships only
/// this WebView (BSD `webview_flutter`) plus the page URL; Regula's proprietary
/// web Face SDK runs remotely on the page. The route is wrapped in the standard
/// Yivi `Scaffold`/app bar, so there is no browser chrome (no URL bar) — it
/// looks fully in-app.
///
/// The route pops with:
/// - `FaceCaptureMessage.completed` when the page posts a `PROCESS_FINISHED`
///   message over the `YiviFace` channel;
/// - `FaceCaptureMessage.aborted` on user back/cancel, a page-load failure or a
///   component error.
class FaceCaptureWebView extends StatefulWidget {
  const FaceCaptureWebView({super.key, required this.captureUrl});

  final Uri captureUrl;

  @override
  State<FaceCaptureWebView> createState() => _FaceCaptureWebViewState();
}

class _FaceCaptureWebViewState extends State<FaceCaptureWebView> {
  late final WebViewController _controller;
  bool _loading = true;

  /// Guards against resolving the route more than once (e.g. a channel message
  /// arriving as the user also taps back).
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel("YiviFace", onMessageReceived: _onChannelMessage)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            // Only a failure of the main capture page is fatal; sub-resource
            // errors (e.g. a favicon) must not abort the session.
            if (error.isForMainFrame ?? true) {
              _resolve(
                FaceCaptureMessage.aborted(
                  "capture page failed to load: ${error.description}",
                ),
              );
            }
          },
        ),
      )
      ..loadRequest(widget.captureUrl);

    // Grant the in-page camera request. `getUserMedia` is served over HTTPS
    // (a secure context), so the WebView surfaces a platform permission request
    // that we forward to the already-granted app-level camera permission.
    final platform = controller.platform;
    if (platform is AndroidWebViewController) {
      platform.setOnPlatformPermissionRequest((request) => request.grant());
    }

    _controller = controller;
  }

  void _onChannelMessage(JavaScriptMessage message) {
    _resolve(faceCaptureMessageFrom(message.message));
  }

  void _resolve(FaceCaptureMessage outcome) {
    if (_resolved || !mounted) return;
    _resolved = true;
    Navigator.of(context).pop(outcome);
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return PopScope(
      // Intercept the hardware/gesture back so it resolves as a cancel (which
      // the service turns into a throw), matching the native build.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _resolve(const FaceCaptureMessage.aborted("cancelled"));
      },
      child: Scaffold(
        backgroundColor: theme.light,
        appBar: IrmaAppBar(
          titleTranslationKey: "face_verification.title",
          leading: YiviBackButton(
            onTap: () =>
                _resolve(const FaceCaptureMessage.aborted("cancelled")),
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_loading)
              ColoredBox(
                color: theme.light,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LoadingIndicator(),
                      SizedBox(height: theme.defaultSpacing),
                      TranslatedText(
                        "face_verification.preparing",
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
