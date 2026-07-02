import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";

import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/providers/email_issuance_provider.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/email/widgets/verify_email_screen.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/widgets/embedded_issuance_expired_screen.dart";
import "package:yivi_core/src/theme/theme.dart";

/// Stub issuer API: sending a code succeeds, but verifying it fails as if the
/// server-side session/token had already expired.
class _ExpiredIssuerApi implements EmailIssuerApi {
  @override
  Future<void> sendEmail({
    required String emailAddress,
    required String language,
  }) async {}

  @override
  Future<SessionPointer> verifyCode({
    required String email,
    required String verificationCode,
  }) async {
    throw EmailIssuanceSessionExpiredError();
  }
}

ProviderContainer _container() {
  final container = ProviderContainer(
    overrides: [emailIssuerApiProvider.overrideWithValue(_ExpiredIssuerApi())],
  );
  addTearDown(container.dispose);
  return container;
}

Widget _verifyScreen(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: IrmaTheme(
      builder: (_) => MaterialApp(
        localizationsDelegates: [
          FlutterI18nDelegate(
            translationLoader: FileTranslationLoader(
              basePath: "assets/locales",
              forcedLocale: const Locale("en", "US"),
            ),
          ),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const VerifyEmailScreen(),
      ),
    ),
  );
}

void main() {
  test(
    "an expired token maps to EmailIssuanceSessionExpiredError, not an invalid code",
    () async {
      final container = _container();
      final notifier = container.read(emailIssuanceProvider.notifier);

      final result = await notifier.verifyCode(code: "ABCDEF");

      // No session pointer is returned and the error is the dedicated expiry
      // error, so the UI can offer a restart rather than "invalid code".
      expect(result, isNull);
      final state = container.read(emailIssuanceProvider);
      expect(state.error, isA<EmailIssuanceSessionExpiredError>());
      expect(state.stage, EmailIssuanceStage.enteringVerificationCode);
    },
  );

  test(
    "restarting from an expired session keeps the email and clears the error",
    () async {
      final container = _container();
      final notifier = container.read(emailIssuanceProvider.notifier);

      await notifier.sendEmail(email: "john.doe@example.com", language: "en");
      await notifier.verifyCode(code: "ABCDEF");
      expect(
        container.read(emailIssuanceProvider).error,
        isA<EmailIssuanceSessionExpiredError>(),
      );

      notifier.goBackToEnteringEmail();

      final state = container.read(emailIssuanceProvider);
      expect(state.stage, EmailIssuanceStage.enteringEmail);
      expect(state.error, isA<EmailIssuanceNoError>());
      expect(state.email, "john.doe@example.com");
    },
  );

  testWidgets(
    "verify screen shows the expired screen and restarting it returns to entering the email",
    (tester) async {
      final container = _container();
      await tester.pumpWidget(_verifyScreen(container));
      // The code field (Pinput) keeps a blinking-cursor animation running, so
      // pumpAndSettle would never settle; pump fixed frames instead. The extra
      // time also lets the async i18n loader resolve the strings.
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      // Before the failure the user sees the code input, not an error.
      expect(
        find.byKey(const Key("email_verification_code_input_field")),
        findsOneWidget,
      );
      expect(find.byType(EmbeddedIssuanceExpiredScreen), findsNothing);

      // Simulate the code being verified against an expired session.
      await container
          .read(emailIssuanceProvider.notifier)
          .verifyCode(code: "ABCDEF");
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // A clear expiry message replaces the (now unusable) code field.
      expect(find.byType(EmbeddedIssuanceExpiredScreen), findsOneWidget);
      expect(
        find.text(
          "This verification code has expired. Start over to send yourself a new code.",
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key("email_verification_code_input_field")),
        findsNothing,
      );

      // The primary action restarts the flow directly.
      await tester.tap(find.byKey(const Key("bottom_bar_primary")));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final state = container.read(emailIssuanceProvider);
      expect(state.stage, EmailIssuanceStage.enteringEmail);
      expect(state.error, isA<EmailIssuanceNoError>());
    },
  );
}
