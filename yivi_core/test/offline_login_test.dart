import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/translation_loader.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/providers/connectivity_provider.dart";
import "package:yivi_core/src/screens/pin/offline_login_screen.dart";
import "package:yivi_core/src/theme/theme.dart";

/// Stub loader that resolves immediately with an empty map. The production
/// FileTranslationLoader reads JSON via rootBundle.loadString — real-time IO
/// that the test framework's fake clock doesn't drive, so pumpAndSettle
/// returns before Localizations rebuilds. These tests assert on widget
/// structure/keys, never on translated content, so an empty map is enough.
class _NoopTranslationLoader extends TranslationLoader {
  @override
  Future<Map> load() async => <String, dynamic>{};
}

/// Fake connectivity service driving the gate deterministically: [isOnline]
/// resolves to [initial] and [onlineChanges] can be pushed via [emit].
class _FakeConnectivityService implements ConnectivityService {
  final bool initial;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  _FakeConnectivityService(this.initial);

  void emit(bool online) => _controller.add(online);

  @override
  Future<bool> isOnline() async => initial;

  @override
  Stream<bool> get onlineChanges => _controller.stream;
}

Widget _wrap(Widget child, ConnectivityService service) {
  return ProviderScope(
    overrides: [connectivityServiceProvider.overrideWithValue(service)],
    child: IrmaTheme(
      builder: (_) => MaterialApp(
        localizationsDelegates: [
          FlutterI18nDelegate(translationLoader: _NoopTranslationLoader()),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: child,
      ),
    ),
  );
}

void main() {
  const offlineKey = ValueKey("offline_login_screen");
  const childKey = ValueKey("pin_placeholder");

  testWidgets("OfflineLoginScreen renders the offline message", (tester) async {
    await tester.pumpWidget(
      _wrap(const OfflineLoginScreen(), _FakeConnectivityService(false)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(offlineKey), findsOneWidget);
  });

  testWidgets("OfflineGate shows the offline screen when offline", (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const OfflineGate(child: SizedBox(key: childKey)),
        _FakeConnectivityService(false),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(offlineKey), findsOneWidget);
    expect(find.byKey(childKey), findsNothing);
  });

  testWidgets("OfflineGate shows the child (PIN screen) when online", (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const OfflineGate(child: SizedBox(key: childKey)),
        _FakeConnectivityService(true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(childKey), findsOneWidget);
    expect(find.byKey(offlineKey), findsNothing);
  });

  testWidgets("OfflineGate swaps back to the child once connectivity returns", (
    tester,
  ) async {
    final service = _FakeConnectivityService(false);
    await tester.pumpWidget(
      _wrap(const OfflineGate(child: SizedBox(key: childKey)), service),
    );
    await tester.pumpAndSettle();

    // Starts offline.
    expect(find.byKey(offlineKey), findsOneWidget);
    expect(find.byKey(childKey), findsNothing);

    // Connectivity returns -> PIN screen comes back.
    service.emit(true);
    await tester.pumpAndSettle();

    expect(find.byKey(childKey), findsOneWidget);
    expect(find.byKey(offlineKey), findsNothing);
  });
}
