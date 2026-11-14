import "dart:async";

import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/models/native_events.dart";
import "package:yivi_core/src/providers/wallet_cards_provider.dart";

import "data_search_test.dart" show pumpFilledAppOnDataPage;
import "helpers/helpers.dart";
import "irma_binding.dart";
import "util.dart";

/// Android's back from a card's details: back on the Data tab with its
/// cards, the app still in front (not sent to the background), in every
/// view, with the old back button and with the predictive back gesture.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group("card-details-back", () {
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    for (final view in WalletView.values) {
      for (final predictive in [false, true]) {
        final how = predictive ? "predictive-back" : "back-button";
        testWidgets("${view.name}-$how", (tester) async {
          await pumpFilledAppOnDataPage(tester, irmaBinding);
          if (view != WalletView.stack) await showWalletView(tester, view);

          final background = <Event>[];
          final sub = irmaBinding.repository.getEvents().listen((e) {
            if (e is AndroidSendToBackgroundEvent) background.add(e);
          });
          addTearDown(sub.cancel);

          // The first card; in the stack only its top shows.
          final card = findAllWalletCards().first;
          await tester.tapAt(tester.getTopLeft(card) + const Offset(60, 24));
          await tester.pumpAndSettle();
          await tester.waitFor(findCredentialDetail());

          await _systemBack(tester, predictive: predictive);
          await tester.pumpAndSettle();

          expect(findCredentialDetail(), findsNothing);
          expect(findAllWalletCards().hitTestable(), findsWidgets);
          expect(background, isEmpty);

          // Once more on the Data tab: now the app goes to the background.
          await _systemBack(tester, predictive: predictive);
          await tester.pumpAndSettle();
          expect(background, hasLength(1));
        });
      }
    }
  });
}

/// Android's system back, as the engine sends it.
Future<void> _systemBack(
  WidgetTester tester, {
  required bool predictive,
}) async {
  if (!predictive) {
    await tester.binding.handlePopRoute();
    return;
  }
  const codec = StandardMethodCodec();
  Future<void> send(String method, [Object? args]) async {
    final done = Completer<void>();
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.backGesture.name,
      codec.encodeMethodCall(MethodCall(method, args)),
      (_) => done.complete(),
    );
    await done.future;
  }

  Map<String, Object?> at(double progress) => {
    "touchOffset": [0.0, 400.0],
    "progress": progress,
    "swipeEdge": 0,
  };
  await send("startBackGesture", at(0));
  for (final p in [0.2, 0.5, 0.8]) {
    await send("updateBackGestureProgress", at(p));
    await tester.pump(const Duration(milliseconds: 16));
  }
  await send("commitBackGesture");
}
