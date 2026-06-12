import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/screens/error/blocked_screen.dart";
import "package:yivi_core/src/screens/error/session_error_screen.dart";
import "package:yivi_core/src/theme/theme.dart";

class TestWidget extends StatelessWidget {
  final SessionError error;

  const TestWidget(this.error);

  @override
  Widget build(BuildContext context) => IrmaTheme(
    builder: (_) => MaterialApp(
      localizationsDelegates: [
        FlutterI18nDelegate(
          translationLoader: FileTranslationLoader(
            basePath: "assets/locales",
            forcedLocale: const Locale("nl", "NL"),
          ),
        ),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: SessionErrorScreen(error: error, onTapClose: () {}),
    ),
  );
}

/// Mount [widget] and wait for the async FlutterI18nDelegate file loader to
/// complete. `pumpAndSettle` runs under the test framework's fake clock and
/// does not drive the real-time IO that `rootBundle.loadString` uses, so the
/// translation Future never resolves and the home widget never builds. Wrap
/// the initial pump in `runAsync` so the file load actually runs, then settle.
Future<void> _pumpWithI18n(WidgetTester tester, Widget widget) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(widget);
    // Give the FileTranslationLoader a chance to read both the active and
    // fallback locale files before we hand control back to fake time.
    await Future<void>.delayed(Duration.zero);
  });
  await tester.pumpAndSettle();
}

void main() {
  const errorScreenKey = ValueKey("error_screen");
  testWidgets("errorType = transport", (WidgetTester tester) async {
    final error = SessionError(errorType: "transport", info: "info");

    await _pumpWithI18n(tester, TestWidget(error));

    expect(find.byKey(const ValueKey("no_internet_screen")), findsOneWidget);
  });

  testWidgets("errorType = pairingRejected", (WidgetTester tester) async {
    final error = SessionError(errorType: "pairingRejected", info: "info");

    await _pumpWithI18n(tester, TestWidget(error));
    expect(find.byKey(errorScreenKey), findsOneWidget);
  });

  testWidgets("remoteError = USER_NOT_FOUND", (WidgetTester tester) async {
    final error = SessionError(
      errorType: "",
      info: "",
      remoteError: RemoteError(errorName: "USER_NOT_FOUND"),
    );

    await _pumpWithI18n(tester, TestWidget(error));
    expect(find.byType(BlockedScreen), findsOneWidget);
  });

  testWidgets("remoteError = SESSION_UNKNOWN", (WidgetTester tester) async {
    final error = SessionError(
      errorType: "",
      info: "",
      remoteError: RemoteError(errorName: "SESSION_UNKNOWN"),
    );

    await _pumpWithI18n(tester, TestWidget(error));
    expect(find.byKey(errorScreenKey), findsOneWidget);
  });

  testWidgets("remoteError = UNEXPECTED_REQUEST", (WidgetTester tester) async {
    final error = SessionError(
      errorType: "",
      info: "",
      remoteError: RemoteError(errorName: "UNEXPECTED_REQUEST"),
    );

    await _pumpWithI18n(tester, TestWidget(error));
    expect(find.byKey(errorScreenKey), findsOneWidget);
  });

  testWidgets("unknown error", (WidgetTester tester) async {
    final error = SessionError(
      errorType: "",
      info: "",
      remoteError: RemoteError(errorName: ""),
    );

    await _pumpWithI18n(tester, TestWidget(error));
    expect(find.byKey(errorScreenKey), findsOneWidget);
  });
}
