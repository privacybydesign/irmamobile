import "dart:convert";
import "dart:io";

import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/models/schemaless/session_state.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/proving_indicator.dart";

/// The indicator shown through the proving wait, and the duration reported
/// afterwards. Both exist to answer the same question -- is this thing working
/// -- so both are covered here.

/// Reads the private painter through dynamic so its state can be asserted
/// without exporting it. The same trick loading_indicator_color_test uses.
dynamic provingPainter(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find.descendant(
      of: find.byType(ProvingIndicator),
      matching: find.byType(CustomPaint),
    ),
  );
  return paint.painter as dynamic;
}

void main() {
  Widget host(Widget child) => IrmaTheme(
    builder: (context) => MaterialApp(
      theme: IrmaTheme.of(context).themeData,
      home: Scaffold(body: Center(child: child)),
    ),
  );

  // pumpAndSettle would hang: the sweep repeats for as long as the wallet is
  // working, which is the whole point of it, so there is no settled state to
  // wait for. Frames are advanced explicitly instead.
  testWidgets("the arc keeps moving while the work runs", (tester) async {
    await tester.pumpWidget(host(const ProvingIndicator()));

    final first = provingPainter(tester).sweep as double;
    await tester.pump(const Duration(milliseconds: 200));
    final second = provingPainter(tester).sweep as double;
    await tester.pump(const Duration(milliseconds: 200));
    final third = provingPainter(tester).sweep as double;

    expect(second, isNot(equals(first)), reason: "a still arc reads as a hang");
    expect(third, isNot(equals(second)));
    expect(provingPainter(tester).completed, isFalse);

    // Ends the repeating ticker so the test tears down cleanly.
    await tester.pumpWidget(host(const ProvingIndicator(completed: true)));
  });

  testWidgets("completing stops the sweep and strokes the check", (
    tester,
  ) async {
    await tester.pumpWidget(host(const ProvingIndicator()));
    await tester.pump(const Duration(milliseconds: 200));
    expect(provingPainter(tester).check, 0.0, reason: "nothing has finished");

    await tester.pumpWidget(host(const ProvingIndicator(completed: true)));
    await tester.pump(const Duration(milliseconds: 400));

    expect(provingPainter(tester).completed, isTrue);
    expect(
      provingPainter(tester).check,
      1.0,
      reason: "the check is drawn once the response has landed",
    );
  });

  test("the reported duration survives the bridge", () {
    // Milliseconds on the wire, a Duration in the app. A wallet that did not
    // measure sends nothing, and null must not become zero: "took 0.0 seconds"
    // is a worse claim than saying nothing at all.
    final measured = SessionState.fromJson({
      "id": 1,
      "protocol": "iso18013-5",
      "type": "disclosure",
      "status": "success",
      "requestor": <String, dynamic>{
        "id": "",
        "name": "",
        "verified": false,
        "anonymous": true,
        "origin": "https://zkp-verifier.com",
      },
      "disclosure_duration_ms": 1180,
    });
    expect(measured.disclosureDuration, const Duration(milliseconds: 1180));

    final unmeasured = SessionState.fromJson({
      "id": 1,
      "protocol": "iso18013-5",
      "type": "disclosure",
      "status": "success",
      "requestor": <String, dynamic>{
        "id": "",
        "name": "",
        "verified": false,
        "anonymous": true,
        "origin": "https://zkp-verifier.com",
      },
    });
    expect(unmeasured.disclosureDurationMs, isNull);
    expect(unmeasured.disclosureDuration, isNull);
  });

  test("the timed explanation carries both substitutions", () {
    // A missing placeholder renders the sentence with a hole in it, and a
    // missing key renders the key itself on screen, so both are pinned. The
    // _markdown segment is what selects the markdown renderer, and the suffix
    // must not lose it.
    final en =
        json.decode(File("assets/locales/en.json").readAsStringSync())
            as Map<String, dynamic>;
    final text = ((en["disclosure"] as Map)["feedback"] as Map)["text"] as Map;

    final timed = text["zero_knowledge_markdown_timed"] as String?;
    expect(timed, isNotNull, reason: "the timed variant must exist");
    expect(timed, contains("{otherParty}"));
    expect(timed, contains("{duration}"));
    expect("zero_knowledge_markdown_timed", contains("_markdown"));

    expect(
      text["zero_knowledge_markdown"],
      isNotNull,
      reason: "the untimed variant still answers an unmeasured disclosure",
    );
  });
}
