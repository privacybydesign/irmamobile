import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/credential_card/card_flight.dart";

import "helpers/credential_factory.dart";
import "helpers/test_translation_loader.dart";
import "support/pump_translated.dart";

final _card = testCredential(type: "pbdf.sidn-pbdf.email", hash: "new");
const _flying = Key("card_flight_card");

void main() {
  final source = GlobalKey(debugLabel: "source");
  final target = GlobalKey(debugLabel: "target");
  late BuildContext page;

  tearDown(CardFlight.reset);

  /// A big card at the top (where it flies from) and a small spot lower down
  /// (where it lands), [spotTop] from the top.
  Future<void> pump(
    WidgetTester tester, {
    double spotTop = 600,
    bool reduceMotion = false,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.reset);
    await pumpTranslated(
      tester,
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
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(400, 800),
              disableAnimations: reduceMotion,
            ),
            child: Builder(
              builder: (context) {
                page = context;
                return Stack(
                  children: [
                    Positioned(
                      left: 21,
                      top: 100,
                      child: SizedBox(key: source, width: 358, height: 226),
                    ),
                    Positioned(
                      left: 33,
                      top: spotTop,
                      child: SizedBox(key: target, width: 58, height: 37),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  bool start({VoidCallback? onDone}) => CardFlight.start(
    page,
    source: source,
    card: _card,
    cardKey: _flying,
    target: (overlay, {required first}) => CardFlight.rectOf(target, overlay),
    onDone: onDone,
  );

  testWidgets("flies from the source and lands on the target", (tester) async {
    await pump(tester);
    var done = 0;
    expect(start(onDone: () => done++), isTrue);
    await tester.pump();
    expect(tester.getRect(find.byKey(_flying)).top, closeTo(100, 1));

    await tester.pump(CardFlight.flight * 0.5);
    final mid = tester.getRect(find.byKey(_flying));
    expect(mid.top, inExclusiveRange(100, 600));
    expect(mid.width, inExclusiveRange(58, 358));

    await tester.pump(CardFlight.flight * 0.49);
    final end = tester.getRect(find.byKey(_flying));
    expect(end.left, closeTo(33, 1));
    expect(end.top, closeTo(600, 1));
    expect(end.width, closeTo(58, 1));

    await tester.pumpAndSettle();
    expect(find.byKey(_flying), findsNothing);
    expect(done, 1);
    expect(CardFlight.isFlying, isFalse);
  });

  testWidgets("follows a target that moves while it flies", (tester) async {
    await pump(tester);
    start();
    await tester.pump();
    await tester.pump(CardFlight.flight * 0.3);
    // The page behind moves (as when the sheet above it slides away).
    await pump(tester, spotTop: 400);
    await tester.pump(CardFlight.flight * 0.69);
    expect(tester.getRect(find.byKey(_flying)).top, closeTo(400, 1));
  });

  testWidgets("one flight at a time, none without a source", (tester) async {
    await pump(tester);
    expect(start(), isTrue);
    expect(start(), isFalse);
    await tester.pumpAndSettle();
    expect(
      CardFlight.start(
        page,
        source: GlobalKey(),
        card: _card,
        target: (overlay, {required first}) => null,
      ),
      isFalse,
    );
  });

  testWidgets("with reduce motion no card flies, and it is done", (
    tester,
  ) async {
    await pump(tester, reduceMotion: true);
    var done = 0;
    expect(start(onDone: () => done++), isTrue);
    await tester.pump();
    expect(find.byKey(_flying), findsNothing);
    await tester.pumpAndSettle();
    expect(done, 1);
  });
}
