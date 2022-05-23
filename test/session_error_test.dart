import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n_delegate.dart';
import 'package:flutter_i18n/loaders/file_translation_loader.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:irmamobile/src/screens/error/blocked_screen.dart';
import 'package:irmamobile/src/screens/error/error_screen.dart';
import 'package:irmamobile/src/screens/error/no_internet_screen.dart';
import 'package:irmamobile/src/screens/error/session_error_screen.dart';
import 'package:irmamobile/src/theme/theme.dart';

class TestWidget extends StatelessWidget {
  final SessionError error;

  const TestWidget(this.error);

  @override
  Widget build(BuildContext context) => IrmaTheme.test(
          widget: MaterialApp(
              localizationsDelegates: [
            FlutterI18nDelegate(
              translationLoader: FileTranslationLoader(
                basePath: 'assets/locales',
                forcedLocale: const Locale('nl', 'NL'),
              ),
            ),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate
          ],
              home: SessionErrorScreen(
                error: error,
                onTapClose: () {},
              )));
}

void main() {
  testWidgets(
    "errorType = transport",
    (WidgetTester tester) async {
      final error = SessionError(errorType: 'transport', info: 'info');

      await tester.pumpWidget(TestWidget(error));
      await tester.pumpAndSettle();

      expect(find.byType(NoInternetScreen), findsOneWidget);
    },
  );

  testWidgets(
    "errorType = pairingRejected",
    (WidgetTester tester) async {
      final error = SessionError(errorType: 'pairingRejected', info: 'info');

      await tester.pumpWidget(TestWidget(error));
      await tester.pumpAndSettle();
      expect(find.byType(ErrorScreen), findsOneWidget);
    },
  );

  testWidgets(
    "remoteError = USER_NOT_FOUND",
    (WidgetTester tester) async {
      final error = SessionError(errorType: '', info: '', remoteError: RemoteError(errorName: 'USER_NOT_FOUND'));

      await tester.pumpWidget(TestWidget(error));
      await tester.pumpAndSettle();
      expect(find.byType(BlockedScreen), findsOneWidget);
    },
  );

  testWidgets(
    "remoteError = SESSION_UNKNOWN",
    (WidgetTester tester) async {
      final error = SessionError(errorType: '', info: '', remoteError: RemoteError(errorName: 'SESSION_UNKNOWN'));

      await tester.pumpWidget(TestWidget(error));
      await tester.pumpAndSettle();
      expect(find.byType(ErrorScreen), findsOneWidget);
    },
  );

  testWidgets(
    "remoteError = UNEXPECTED_REQUEST",
    (WidgetTester tester) async {
      final error = SessionError(errorType: '', info: '', remoteError: RemoteError(errorName: 'UNEXPECTED_REQUEST'));

      await tester.pumpWidget(TestWidget(error));
      await tester.pumpAndSettle();
      expect(find.byType(ErrorScreen), findsOneWidget);
    },
  );

  testWidgets(
    "unknown error",
    (WidgetTester tester) async {
      final error = SessionError(errorType: '', info: '', remoteError: RemoteError(errorName: ''));

      await tester.pumpWidget(TestWidget(error));
      await tester.pumpAndSettle();
      expect(find.byType(ErrorScreen), findsOneWidget);
    },
  );
}
