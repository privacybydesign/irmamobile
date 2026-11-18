import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/screens/error/blocked_screen.dart";
import "package:yivi_core/src/screens/error/session_error_screen.dart";

import "support/pump_translated.dart";
import "support/test_app.dart";

class TestWidget extends StatelessWidget {
  final SessionError error;

  const TestWidget(this.error);

  @override
  Widget build(BuildContext context) =>
      testApp(SessionErrorScreen(error: error, onTapClose: () {}));
}

void main() {
  const errorScreenKey = ValueKey("error_screen");
  testWidgets("errorType = transport", (WidgetTester tester) async {
    final error = SessionError(errorType: "transport", info: "info");

    await pumpTranslated(tester, TestWidget(error));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey("no_internet_screen")), findsOneWidget);
  });

  testWidgets("errorType = pairingRejected", (WidgetTester tester) async {
    final error = SessionError(errorType: "pairingRejected", info: "info");

    await pumpTranslated(tester, TestWidget(error));
    await tester.pumpAndSettle();
    expect(find.byKey(errorScreenKey), findsOneWidget);
  });

  testWidgets("remoteError = USER_NOT_FOUND", (WidgetTester tester) async {
    final error = SessionError(
      errorType: "",
      info: "",
      remoteError: RemoteError(errorName: "USER_NOT_FOUND"),
    );

    await pumpTranslated(tester, TestWidget(error));
    await tester.pumpAndSettle();
    expect(find.byType(BlockedScreen), findsOneWidget);
  });

  testWidgets("remoteError = SESSION_UNKNOWN", (WidgetTester tester) async {
    final error = SessionError(
      errorType: "",
      info: "",
      remoteError: RemoteError(errorName: "SESSION_UNKNOWN"),
    );

    await pumpTranslated(tester, TestWidget(error));
    await tester.pumpAndSettle();
    expect(find.byKey(errorScreenKey), findsOneWidget);
  });

  testWidgets("remoteError = UNEXPECTED_REQUEST", (WidgetTester tester) async {
    final error = SessionError(
      errorType: "",
      info: "",
      remoteError: RemoteError(errorName: "UNEXPECTED_REQUEST"),
    );

    await pumpTranslated(tester, TestWidget(error));
    await tester.pumpAndSettle();
    expect(find.byKey(errorScreenKey), findsOneWidget);
  });

  testWidgets("unknown error", (WidgetTester tester) async {
    final error = SessionError(
      errorType: "",
      info: "",
      remoteError: RemoteError(errorName: ""),
    );

    await pumpTranslated(tester, TestWidget(error));
    await tester.pumpAndSettle();
    expect(find.byKey(errorScreenKey), findsOneWidget);
  });
}
