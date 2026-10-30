import "dart:async";

import "package:material_ui/material_ui.dart";
import "package:webview_flutter/webview_flutter.dart";
import "package:webview_flutter_android/webview_flutter_android.dart";
import "package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart";

import "../../theme/theme.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/loading_indicator.dart";
import "../scanner/util/handle_camera_permission.dart";
import "document_scan_outcome.dart";

/// Lets the user photograph the front and back of their identity document on
/// a document scan service's page, shown full screen inside the app.
///
/// [url] is the scan link the business wallet created, and [returnUrl] the URL
/// the scan page redirects to when the user is done.
Future<DocumentScanOutcome> startDocumentScan(
  BuildContext context, {
  required Uri url,
  required Uri returnUrl,
}) async {
  // The web view can only hand the page the camera once the app holds the
  // camera permission itself.
  if (!await handleCameraPermission(context)) {
    return const DocumentScanFailed(DocumentScanFailure.cameraDenied);
  }
  if (!context.mounted) return const DocumentScanCancelled();

  final outcome = await Navigator.of(context).push<DocumentScanOutcome>(
    MaterialPageRoute(
      builder: (context) => DocumentScanWebView(url: url, returnUrl: returnUrl),
    ),
  );
  return outcome ?? const DocumentScanCancelled();
}

/// Full-screen route that loads a document scan page in an embedded WebView,
/// with the in-page camera enabled. Pops with a [DocumentScanOutcome].
///
/// The page must only ask for the camera: on iOS, any microphone request
/// (even one that is denied) kills the app, as it has no microphone usage
/// description.
class DocumentScanWebView extends StatefulWidget {
  const DocumentScanWebView({
    super.key,
    required this.url,
    required this.returnUrl,
  });

  final Uri url;
  final Uri returnUrl;

  @override
  State<DocumentScanWebView> createState() => _DocumentScanWebViewState();
}

class _DocumentScanWebViewState extends State<DocumentScanWebView> {
  late final WebViewController _controller;
  bool _loading = true;

  /// The page currently loading in the main frame, so an HTTP error on it
  /// (e.g. an expired link) can be told apart from one on an image or script.
  late Uri _mainFrameUrl = widget.url;

  /// Guards against resolving the route more than once (e.g. a redirect
  /// arriving as the user also taps back).
  bool _resolved = false;

  @override
  void initState() {
    super.initState();

    // On iOS the camera preview is a <video> element: without inline playback
    // WKWebView takes it fullscreen, and without dropping the user-action
    // requirement the stream never starts playing.
    final PlatformWebViewControllerCreationParams params =
        WebViewPlatform.instance is WebKitWebViewPlatform
        ? WebKitWebViewControllerCreationParams(
            allowsInlineMediaPlayback: true,
            mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
          )
        : const PlatformWebViewControllerCreationParams();

    final controller =
        WebViewController.fromPlatformCreationParams(
            params,
            // Only the camera: the page can also ask for the microphone or
            // other resources, and a document scan needs none of them.
            onPermissionRequest: (request) =>
                request.types.every(
                  (t) => t == WebViewPermissionResourceType.camera,
                )
                ? request.grant()
                : request.deny(),
          )
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onNavigationRequest: _onNavigationRequest,
              // A page can also change the URL without a navigation request
              // (history.pushState), which only shows up here.
              onUrlChange: (change) {
                final url = Uri.tryParse(change.url ?? "");
                if (url != null &&
                    isDocumentScanReturnUrl(url, widget.returnUrl)) {
                  _resolve(documentScanOutcomeFromReturnUrl(url));
                }
              },
              onPageStarted: (url) {
                _mainFrameUrl = Uri.tryParse(url) ?? _mainFrameUrl;
              },
              onPageFinished: (_) {
                if (mounted) setState(() => _loading = false);
              },
              onHttpError: (error) {
                if (error.request?.uri == _mainFrameUrl) {
                  _resolve(
                    const DocumentScanFailed(DocumentScanFailure.pageFailed),
                  );
                }
              },
              onWebResourceError: (error) {
                // Only a failure of the main page is fatal; sub-resource errors
                // (e.g. a favicon) must not abort the scan.
                if (error.isForMainFrame ?? true) {
                  _resolve(
                    const DocumentScanFailed(DocumentScanFailure.pageFailed),
                  );
                }
              },
            ),
          );

    final platform = controller.platform;
    if (platform is AndroidWebViewController) {
      // Android WebView requires a user gesture before any media playback,
      // unlike browsers, which autoplay a camera MediaStream freely. Without
      // this the page acquires the stream and then fails to play it.
      unawaited(platform.setMediaPlaybackRequiresUserGesture(false));
    }

    // Load only once the platform settings above are in place, so the page is
    // never evaluated under the default autoplay policy.
    unawaited(_load(controller));
    _controller = controller;
  }

  Future<void> _load(WebViewController controller) async {
    try {
      await controller.loadRequest(widget.url);
    } catch (_) {
      // Without a load no onWebResourceError will ever fire; resolve
      // explicitly rather than leaving the user on a permanent spinner.
      _resolve(const DocumentScanFailed(DocumentScanFailure.pageFailed));
    }
  }

  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    // Frames inside the scan page stay contained in it; only what the main frame
    // shows needs checking.
    if (!request.isMainFrame) return NavigationDecision.navigate;

    final url = Uri.tryParse(request.url);
    if (url == null) return NavigationDecision.prevent;
    if (isDocumentScanReturnUrl(url, widget.returnUrl)) {
      // Never load the return URL itself: the app handles the end of the scan.
      _resolve(documentScanOutcomeFromReturnUrl(url));
      return NavigationDecision.prevent;
    }
    return isDocumentScanPage(url, widget.url)
        ? NavigationDecision.navigate
        : NavigationDecision.prevent;
  }

  void _resolve(DocumentScanOutcome outcome) {
    if (_resolved || !mounted) return;
    _resolved = true;
    Navigator.of(context).pop(outcome);
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _resolve(const DocumentScanCancelled());
      },
      child: Scaffold(
        backgroundColor: theme.light,
        appBar: IrmaAppBar(
          titleTranslationKey: "document_scan.title",
          leading: YiviBackButton(
            onTap: () => _resolve(const DocumentScanCancelled()),
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_loading)
              ColoredBox(
                color: theme.light,
                child: Center(child: LoadingIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
