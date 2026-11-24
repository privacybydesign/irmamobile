import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/data/wallet/wallet_detail_scaffold.dart";

import "support/card_details_host.dart";
import "support/test_app.dart";

void main() {
  testWidgets("a hard pull down closes the details and nothing under them", (
    tester,
  ) async {
    // The page below, like home: a pop that reaches it sends the app to the
    // background.
    var popsBelow = 0;
    final host = CardDetailsHost();
    await tester.pumpWidget(
      testApp(
        PopScope(
          canPop: false,
          onPopInvokedWithResult: (_, _) => popsBelow++,
          child: host.build(below: const Scaffold(body: Text("below"))),
        ),
      ),
    );
    await tester.pumpAndSettle();

    host.open(
      "detail",
      details: (context, transition) => WalletDetailScaffold(
        transition: transition,
        closeKey: const Key("detail_close"),
        builder: (context, physics) => ListView(
          key: const Key("detail_list"),
          physics: physics,
          children: [
            for (var i = 0; i < 30; i++)
              SizedBox(height: 80, child: Text("row $i")),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("row 0"), findsOneWidget);

    await tester.fling(
      find.byKey(const Key("detail_list")),
      const Offset(0, 500),
      4000,
    );
    await tester.pumpAndSettle();

    expect(find.text("row 0"), findsNothing);
    expect(host.current, isNull);
    expect(find.text("below"), findsOneWidget);
    expect(popsBelow, 0);
  });
}
