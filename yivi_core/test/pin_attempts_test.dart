import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/pin/yivi_pin_screen.dart";

import "support/pump_translated.dart";

// The attempts as both PIN screens show them (unlocking, and a session's
// PIN), and the short PIN that submits itself once full.

Future<BuildContext> _context(WidgetTester tester) async {
  late BuildContext context;
  await pumpTranslated(
    tester,
    MaterialApp(
      localizationsDelegates: [
        FlutterI18nDelegate(
          translationLoader: FileTranslationLoader(
            basePath: "assets/locales",
            forcedLocale: const Locale("en", "US"),
          ),
        ),
      ],
      home: Builder(
        builder: (c) {
          context = c;
          return const SizedBox();
        },
      ),
    ),
  );
  return context;
}

EnterPinState _pin(List<int> digits) => EnterPinState.createFrom(pin: digits);

void main() {
  testWidgets("nothing to say: no line, no error", (tester) async {
    final attempts = PinAttempts.of(
      await _context(tester),
      blockedFor: Duration.zero,
      blocked: false,
      wrong: false,
      left: 3,
    );
    expect(attempts.line, isNull);
    expect(attempts.detailKind, PinDetailKind.info);
    expect(attempts.pinError, isFalse);
  });

  testWidgets("a wrong PIN: the tries left, as an error, dots red", (
    tester,
  ) async {
    final attempts = PinAttempts.of(
      await _context(tester),
      blockedFor: Duration.zero,
      blocked: false,
      wrong: true,
      left: 2,
    );
    expect(attempts.line, contains("2 tries left"));
    expect(attempts.detailKind, PinDetailKind.error);
    expect(attempts.pinError, isTrue);
  });

  testWidgets("blocked: when to try again, the dots not red", (tester) async {
    final attempts = PinAttempts.of(
      await _context(tester),
      blockedFor: const Duration(minutes: 1),
      blocked: true,
      wrong: true,
      left: 0,
    );
    expect(attempts.line, startsWith("Try again in"));
    expect(attempts.detailKind, PinDetailKind.error);
    expect(attempts.pinError, isFalse);
  });

  testWidgets("a short PIN submits itself once full", (tester) async {
    final context = await _context(tester);
    final submitted = <String>[];
    final listener = submitWhenFull(shortPinSize, submitted.add);

    listener(context, _pin([1, 2, 3, 4]));
    expect(submitted, isEmpty);
    listener(context, _pin([1, 2, 3, 4, 5]));
    expect(submitted, ["12345"]);

    // Not while the pad is off, and never a long PIN.
    submitWhenFull(shortPinSize, submitted.add, enabled: false)(
      context,
      _pin([1, 2, 3, 4, 5]),
    );
    submitWhenFull(longPinSize, submitted.add)(context, _pin([1, 2, 3, 4, 5]));
    expect(submitted, ["12345"]);
  });
}
