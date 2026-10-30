import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart";
import "package:yivi_core/src/screens/document_scan/document_scan_outcome.dart";
import "package:yivi_core/src/screens/document_scan/document_scan_web_view.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/irma_app_bar.dart";

import "helpers/test_translation_loader.dart";

final _scanUrl = Uri.parse("https://scan.example.com/en-us/abc123");
final _returnUrl = Uri.parse("https://wallet.example.com/document-scan/return");

void main() {
  group("isDocumentScanReturnUrl", () {
    test("matches the return URL with the parameters added", () {
      expect(
        isDocumentScanReturnUrl(
          Uri.parse("$_returnUrl?trxid=t1&state=completed&resultid=r1"),
          _returnUrl,
        ),
        isTrue,
      );
    });

    test("does not match a longer path that starts the same", () {
      expect(
        isDocumentScanReturnUrl(
          Uri.parse("https://wallet.example.com/document-scan/return-other"),
          _returnUrl,
        ),
        isFalse,
      );
    });

    test("does not match another host or scheme", () {
      expect(
        isDocumentScanReturnUrl(
          Uri.parse("https://evil.example.com/document-scan/return"),
          _returnUrl,
        ),
        isFalse,
      );
      expect(
        isDocumentScanReturnUrl(
          Uri.parse("http://wallet.example.com/document-scan/return"),
          _returnUrl,
        ),
        isFalse,
      );
    });
  });

  group("documentScanOutcomeFromReturnUrl", () {
    test("reads the transaction, state and result", () {
      expect(
        documentScanOutcomeFromReturnUrl(
          Uri.parse("$_returnUrl?trxid=t1&state=completed&resultid=r1"),
        ),
        const DocumentScanFinished(
          transactionId: "t1",
          state: DocumentScanState.completed,
          resultId: "r1",
        ),
      );
    });

    test("has no result for a failed scan", () {
      expect(
        documentScanOutcomeFromReturnUrl(
          Uri.parse("$_returnUrl?trxid=t1&state=failed"),
        ),
        const DocumentScanFinished(
          transactionId: "t1",
          state: DocumentScanState.failed,
        ),
      );
    });

    test("keeps an unknown state as unknown", () {
      expect(
        documentScanOutcomeFromReturnUrl(
          Uri.parse("$_returnUrl?trxid=t1&state=something_new"),
        ),
        const DocumentScanFinished(
          transactionId: "t1",
          state: DocumentScanState.unknown,
        ),
      );
    });

    test("fails without a transaction ID", () {
      expect(
        documentScanOutcomeFromReturnUrl(
          Uri.parse("$_returnUrl?state=completed"),
        ),
        const DocumentScanFailed(DocumentScanFailure.pageFailed),
      );
    });
  });

  group("isDocumentScanPage", () {
    test("allows HTTPS pages on the scan link's host", () {
      expect(
        isDocumentScanPage(
          Uri.parse("https://scan.example.com/en-us/abc123/back"),
          _scanUrl,
        ),
        isTrue,
      );
    });

    test("blocks other hosts and plain HTTP", () {
      expect(
        isDocumentScanPage(Uri.parse("https://example.org/"), _scanUrl),
        isFalse,
      );
      expect(
        isDocumentScanPage(
          Uri.parse("http://scan.example.com/en-us/abc123"),
          _scanUrl,
        ),
        isFalse,
      );
    });
  });

  group("DocumentScanWebView", () {
    late _FakeWebViewPlatform platform;

    setUp(() {
      platform = _FakeWebViewPlatform();
      WebViewPlatform.instance = platform;
    });

    testWidgets("loads the scan link", (tester) async {
      await _openScan(tester);

      expect(platform.controller.loaded, [_scanUrl]);
    });

    testWidgets("finishes on the return URL without loading it", (
      tester,
    ) async {
      final outcome = await _openScan(tester);

      final decision = await platform.delegate.onNavigationRequest!(
        NavigationRequest(
          url: "$_returnUrl?trxid=t1&state=completed&resultid=r1",
          isMainFrame: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(decision, NavigationDecision.prevent);
      expect(
        await outcome,
        const DocumentScanFinished(
          transactionId: "t1",
          state: DocumentScanState.completed,
          resultId: "r1",
        ),
      );
    });

    testWidgets("finishes when the page changes the URL to the return URL", (
      tester,
    ) async {
      final outcome = await _openScan(tester);

      platform.delegate.onUrlChange!(
        UrlChange(url: "$_returnUrl?trxid=t1&state=failed"),
      );
      await tester.pumpAndSettle();

      expect(
        await outcome,
        const DocumentScanFinished(
          transactionId: "t1",
          state: DocumentScanState.failed,
        ),
      );
    });

    testWidgets("allows pages on the scan host and blocks other sites", (
      tester,
    ) async {
      await _openScan(tester);
      final onNavigationRequest = platform.delegate.onNavigationRequest!;

      expect(
        await onNavigationRequest(
          const NavigationRequest(
            url: "https://scan.example.com/en-us/abc123/back",
            isMainFrame: true,
          ),
        ),
        NavigationDecision.navigate,
      );
      expect(
        await onNavigationRequest(
          const NavigationRequest(
            url: "https://example.org/",
            isMainFrame: true,
          ),
        ),
        NavigationDecision.prevent,
      );
      // Frames stay inside the scan page, so they are not checked.
      expect(
        await onNavigationRequest(
          const NavigationRequest(
            url: "https://example.org/frame",
            isMainFrame: false,
          ),
        ),
        NavigationDecision.navigate,
      );
      expect(find.byType(DocumentScanWebView), findsOneWidget);
    });

    testWidgets("cancels on back", (tester) async {
      final outcome = await _openScan(tester);

      await tester.tap(find.byType(YiviBackButton));
      await tester.pumpAndSettle();

      expect(await outcome, const DocumentScanCancelled());
    });

    testWidgets("fails when the scan page does not load", (tester) async {
      final outcome = await _openScan(tester);

      platform.delegate.onWebResourceError!(
        const WebResourceError(
          errorCode: -2,
          description: "net::ERR_NAME_NOT_RESOLVED",
          isForMainFrame: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        await outcome,
        const DocumentScanFailed(DocumentScanFailure.pageFailed),
      );
    });

    testWidgets("fails on an HTTP error for the scan page, like an expired "
        "link", (tester) async {
      final outcome = await _openScan(tester);

      platform.delegate.onHttpError!(
        HttpResponseError(
          request: WebResourceRequest(uri: _scanUrl),
          response: WebResourceResponse(uri: _scanUrl, statusCode: 410),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        await outcome,
        const DocumentScanFailed(DocumentScanFailure.pageFailed),
      );
    });

    testWidgets("ignores errors on images and other parts of the page", (
      tester,
    ) async {
      await _openScan(tester);

      final image = Uri.parse("https://scan.example.com/favicon.ico");
      platform.delegate.onHttpError!(
        HttpResponseError(
          request: WebResourceRequest(uri: image),
          response: WebResourceResponse(uri: image, statusCode: 404),
        ),
      );
      platform.delegate.onWebResourceError!(
        const WebResourceError(
          errorCode: -1,
          description: "failed",
          isForMainFrame: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DocumentScanWebView), findsOneWidget);
    });

    testWidgets("gives the page the camera and nothing else", (tester) async {
      await _openScan(tester);
      final onPermissionRequest = platform.controller.onPermissionRequest!;

      final camera = _FakePermissionRequest({
        WebViewPermissionResourceType.camera,
      });
      final cameraAndMicrophone = _FakePermissionRequest({
        WebViewPermissionResourceType.camera,
        WebViewPermissionResourceType.microphone,
      });
      onPermissionRequest(camera);
      onPermissionRequest(cameraAndMicrophone);

      expect(camera.granted, isTrue);
      expect(cameraAndMicrophone.granted, isFalse);
    });
  });
}

/// Pushes the scan route and returns what it pops with.
Future<Future<DocumentScanOutcome?>> _openScan(WidgetTester tester) async {
  late Future<DocumentScanOutcome?> outcome;
  await tester.pumpWidget(
    IrmaTheme(
      builder: (_) => MaterialApp(
        localizationsDelegates: [
          FlutterI18nDelegate(
            translationLoader: TestTranslationLoader(
              basePath: "assets/locales",
              forcedLocale: const Locale("en", "US"),
            ),
          ),
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => outcome = Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    DocumentScanWebView(url: _scanUrl, returnUrl: _returnUrl),
              ),
            ),
            child: const Text("open"),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text("open"));
  // The loading indicator animates until the page finishes, so settle on a
  // finished page.
  await tester.pump();
  _platformOf().delegate.onPageFinished!(_scanUrl.toString());
  await tester.pumpAndSettle();
  return outcome;
}

_FakeWebViewPlatform _platformOf() =>
    WebViewPlatform.instance! as _FakeWebViewPlatform;

class _FakeWebViewPlatform extends WebViewPlatform {
  late _FakeController controller;
  late _FakeNavigationDelegate delegate;

  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) => controller = _FakeController(params);

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) => delegate = _FakeNavigationDelegate(params);

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) => _FakeWebViewWidget(params);
}

class _FakeController extends PlatformWebViewController {
  _FakeController(super.params) : super.implementation();

  final loaded = <Uri>[];
  void Function(PlatformWebViewPermissionRequest)? onPermissionRequest;

  @override
  Future<void> loadRequest(LoadRequestParams params) async {
    loaded.add(params.uri);
  }

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}

  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate handler,
  ) async {}

  @override
  Future<void> setOnPlatformPermissionRequest(
    void Function(PlatformWebViewPermissionRequest request) onPermissionRequest,
  ) async {
    this.onPermissionRequest = onPermissionRequest;
  }
}

class _FakeNavigationDelegate extends PlatformNavigationDelegate {
  _FakeNavigationDelegate(super.params) : super.implementation();

  NavigationRequestCallback? onNavigationRequest;
  PageEventCallback? onPageStarted;
  PageEventCallback? onPageFinished;
  HttpResponseErrorCallback? onHttpError;
  WebResourceErrorCallback? onWebResourceError;
  UrlChangeCallback? onUrlChange;

  @override
  Future<void> setOnNavigationRequest(
    NavigationRequestCallback onNavigationRequest,
  ) async => this.onNavigationRequest = onNavigationRequest;

  @override
  Future<void> setOnPageStarted(PageEventCallback onPageStarted) async =>
      this.onPageStarted = onPageStarted;

  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async =>
      this.onPageFinished = onPageFinished;

  @override
  Future<void> setOnHttpError(HttpResponseErrorCallback onHttpError) async =>
      this.onHttpError = onHttpError;

  @override
  Future<void> setOnWebResourceError(
    WebResourceErrorCallback onWebResourceError,
  ) async => this.onWebResourceError = onWebResourceError;

  @override
  Future<void> setOnUrlChange(UrlChangeCallback onUrlChange) async =>
      this.onUrlChange = onUrlChange;
}

class _FakeWebViewWidget extends PlatformWebViewWidget {
  _FakeWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

class _FakePermissionRequest extends PlatformWebViewPermissionRequest {
  _FakePermissionRequest(Set<WebViewPermissionResourceType> types)
    : super(types: types);

  final _decisions = <bool>[];

  bool? get granted => _decisions.lastOrNull;

  @override
  Future<void> grant() async => _decisions.add(true);

  @override
  Future<void> deny() async => _decisions.add(false);
}
