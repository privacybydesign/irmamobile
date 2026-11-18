import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/theme/theme.dart";

import "support/test_app.dart";

final _word = Provider<String>((ref) => "real");

/// Records what the shell gives the widgets under it.
class _Probe extends ConsumerWidget {
  const _Probe(this.seen);

  final List<Object> seen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    seen
      ..clear()
      ..addAll([
        YiviTheme.of(context),
        FlutterI18n.translate(context, "ui.cancel"),
        ref.watch(_word),
      ]);
    return const SizedBox();
  }
}

void main() {
  testWidgets("light gives the light YiviThemeData and the app's theme", (
    tester,
  ) async {
    final seen = <Object>[];
    await pumpTestApp(tester, _Probe(seen));
    final data = seen[0] as YiviThemeData;
    expect(data.isDark, isFalse);
    final context = tester.element(find.byType(_Probe));
    expect(Theme.of(context).brightness, Brightness.light);
    expect(
      Theme.of(context).scaffoldBackgroundColor,
      data.themeData.scaffoldBackgroundColor,
    );
  });

  testWidgets("dark gives the dark YiviThemeData", (tester) async {
    final seen = <Object>[];
    await pumpTestApp(tester, _Probe(seen), brightness: Brightness.dark);
    expect((seen[0] as YiviThemeData).isDark, isTrue);
    final context = tester.element(find.byType(_Probe));
    expect(Theme.of(context).brightness, Brightness.dark);
  });

  testWidgets("the locale files load, in English by default", (tester) async {
    final seen = <Object>[];
    await pumpTestApp(tester, _Probe(seen));
    expect(seen[1], "Cancel");
  });

  testWidgets("another locale loads its own file", (tester) async {
    final seen = <Object>[];
    await pumpTestApp(tester, _Probe(seen), locale: const Locale("nl", "NL"));
    expect(seen[1], "Annuleren");
  });

  testWidgets("overrides apply", (tester) async {
    final seen = <Object>[];
    await pumpTestApp(
      tester,
      _Probe(seen),
      overrides: [_word.overrideWithValue("fake")],
    );
    expect(seen[2], "fake");
  });

  group("size", () {
    late Size before;
    late double ratioBefore;

    testWidgets("sets the view at pixel ratio 1", (tester) async {
      before = tester.view.physicalSize;
      ratioBefore = tester.view.devicePixelRatio;
      await pumpTestApp(tester, const SizedBox(), size: const Size(874, 402));
      expect(tester.view.physicalSize, const Size(874, 402));
      expect(tester.view.devicePixelRatio, 1);
      final context = tester.element(find.byType(SizedBox).last);
      expect(MediaQuery.sizeOf(context), const Size(874, 402));
    });

    testWidgets("is reset after the test", (tester) async {
      expect(tester.view.physicalSize, before);
      expect(tester.view.devicePixelRatio, ratioBefore);
    });
  });
}
