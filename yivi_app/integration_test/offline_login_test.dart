// Verifies the offline gate introduced for issue #618: when the device has no
// network connection, the lock overlay shows a "connection required" message
// instead of the PIN pad. A PIN entered while offline can only fail against the
// keyshare server, and a quickly-dismissed failure is indistinguishable from a
// wrong PIN — so users retry a correct PIN over and over. The gate recovers on
// its own: once connectivity returns, the PIN screen comes back automatically.
//
// The gate's widget-level behaviour is covered by yivi_core's
// offline_login_test.dart. This exercises it against the real LockGate /
// GoRouter / repository stack, driving connectivity through a fake service.

import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:yivi_core/src/providers/connectivity_provider.dart";
import "package:yivi_core/src/screens/data/data_tab.dart";
import "package:yivi_core/src/screens/pin/offline_login_screen.dart";
import "package:yivi_core/src/screens/pin/pin_screen.dart";

import "helpers/helpers.dart";
import "irma_binding.dart";
import "util.dart";

/// Fake connectivity service driving the gate deterministically: [isOnline]
/// resolves to the current [_online] value and [emit] pushes live changes onto
/// [onlineChanges].
class _FakeConnectivityService implements ConnectivityService {
  bool _online;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  _FakeConnectivityService({required bool online}) : _online = online;

  void emit(bool online) {
    _online = online;
    _controller.add(online);
  }

  @override
  Future<bool> isOnline() async => _online;

  @override
  Stream<bool> get onlineChanges => _controller.stream;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  final offlineScreenFinder = find.byType(OfflineLoginScreen);
  final pinScreenFinder = find.byType(PinScreen);

  group("offline-login", () {
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets(
      "offline at startup shows the connection message instead of the PIN screen, then recovers",
      (tester) async {
        final connectivity = _FakeConnectivityService(online: false);

        await pumpYiviApp(
          tester,
          irmaBinding.repository,
          providerOverrides: [
            connectivityServiceProvider.overrideWithValue(connectivity),
          ],
        );

        // The lock overlay is up, but offline it shows the connection message,
        // not the PIN pad — so the user is never asked for a PIN that can only
        // fail (issue #618).
        await tester.waitFor(offlineScreenFinder);
        expect(pinScreenFinder, findsNothing);
        expect(find.text("No internet connection"), findsOneWidget);
        expect(
          find.text(
            "An internet connection is required to log in. Please check your connection and try again.",
          ),
          findsOneWidget,
        );

        // Connectivity returns: the gate swaps back to the PIN screen on its
        // own, with no button to tap.
        connectivity.emit(true);
        await tester.waitFor(pinScreenFinder);
        expect(offlineScreenFinder, findsNothing);

        // And the recovered PIN screen unlocks the app as usual.
        await unlockAndWaitForHome(tester);
      },
    );

    testWidgets(
      "losing connectivity at the lock screen swaps the PIN screen for the message",
      (tester) async {
        final connectivity = _FakeConnectivityService(online: true);

        await pumpYiviApp(
          tester,
          irmaBinding.repository,
          providerOverrides: [
            connectivityServiceProvider.overrideWithValue(connectivity),
          ],
        );

        // Online at startup: the lock overlay shows the PIN screen.
        await tester.waitFor(pinScreenFinder);
        expect(offlineScreenFinder, findsNothing);

        // Connection drops while the user is looking at the PIN screen: the
        // gate replaces it with the connection message.
        connectivity.emit(false);
        await tester.waitFor(offlineScreenFinder);
        expect(pinScreenFinder, findsNothing);

        // Connection returns: back to the PIN screen, and unlocking works.
        connectivity.emit(true);
        await tester.waitFor(pinScreenFinder);
        expect(offlineScreenFinder, findsNothing);

        await unlockAndWaitForHome(tester);
        expect(find.byType(DataTab), findsOneWidget);
      },
    );
  });
}
