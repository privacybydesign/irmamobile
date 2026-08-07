// yivi_core exposes its theme and shared widgets only under lib/src (no public
// barrel), so the Yivi chrome here must import them by their src path.
// ignore_for_file: implementation_imports
import "dart:async";

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
      );

    // Grant the in-page camera request. `getUserMedia` is served over HTTPS
    // (a secure context), so the WebView surfaces a platform permission request
    // that we forward to the already-granted app-level camera permission.
    final platform = controller.platform;
    if (platform is AndroidWebViewController) {
      platform.setOnPlatformPermissionRequest((request) => request.grant());
      // Android WebView requires a user gesture before any media playback,
      // unlike browsers, which autoplay a camera MediaStream freely. Without
      // this the capture page acquires the stream and then dies on
      // `NotAllowedError: play() can only be initiated by a user gesture`,
      // leaving a live but invisible camera.
      unawaited(platform.setMediaPlaybackRequiresUserGesture(false));
    }

    // Load only once the platform settings above are in place, so the page is
    // never evaluated under the default autoplay policy.
    unawaited(_loadCapturePage(controller));
    _controller = controller;
  }

  /// Clears the WebView cache, then loads the capture page.
  ///
  /// The page is served without `Cache-Control` or `ETag`, so the WebView falls
  /// back to heuristic freshness and can pin a stale build — and with it a stale
  /// Face API URL, yielding liveness transactions the issuer cannot resolve.
  /// Clearing also covers the lazily-loaded chunks the page pulls in, which a
  /// request header on the document could not reach. The durable fix is
  /// `Cache-Control: no-store` on the served page.
  Future<void> _loadCapturePage(WebViewController controller) async {
    try {
      await controller.clearCache();
      await controller.loadRequest(widget.captureUrl);
    } catch (e) {
      // Without a load there is nothing to capture with, and no
      // onWebResourceError will ever fire; fail the session explicitly rather
      // than leaving the user on a permanent spinner.
      _resolve(FaceCaptureMessage.aborted("capture page failed to load: $e"));
    }
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
