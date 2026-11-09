import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/irma_bridge.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/clear_all_data_event.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/screens/enrollment/widgets/wallet_deleted_confirmation.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/irma_dialog.dart";

import "helpers/test_translation_loader.dart";

// UNINST-11.5-01: once the wallet is wiped, the enrollment screen it lands on
// confirms that the wallet and its data are gone.

class _RecordingBridge extends IrmaBridge {
  @override
  void dispatch(Event event) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const englishTitle = "Wallet removed";
  const englishBody =
      "Your wallet has been removed and all its data has been deleted";
  const dutchTitle = "Wallet verwijderd";
  const dutchBody = "Je wallet en al je gegevens zijn verwijderd";

  Future<IrmaRepository> repository() async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await IrmaPreferences.fromInstance(
      mostRecentTermsUrlNl: "",
      mostRecentTermsUrlEn: "",
    );
    return IrmaRepository(client: _RecordingBridge(), preferences: preferences);
  }

  Future<void> pumpConfirmation(
    WidgetTester tester, {
    required IrmaRepository repo,
    Locale locale = const Locale("en", "US"),
  }) async {
    final widget = IrmaRepositoryProvider(
      repository: repo,
      child: IrmaTheme(
        builder: (_) => MaterialApp(
          localizationsDelegates: [
            FlutterI18nDelegate(
              translationLoader: TestTranslationLoader(
                basePath: "assets/locales",
                forcedLocale: locale,
              ),
            ),
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: const Scaffold(
            body: WalletDeletedConfirmation(child: SizedBox()),
          ),
        ),
      ),
    );

    // See error_reporting_check_box_semantics_test.dart: the locale JSON loads
    // with real IO, which the fake clock does not drive.
    await tester.runAsync(() async {
      await tester.pumpWidget(widget);
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();
  }

  group("IrmaRepository.consumeWalletDeleted", () {
    test("is false until the wallet is wiped", () async {
      final repo = await repository();
      addTearDown(repo.close);

      expect(repo.consumeWalletDeleted(), isFalse);
    });

    test("is true once after a wipe", () async {
      final repo = await repository();
      addTearDown(repo.close);

      repo.bridgedDispatch(ClearAllDataEvent());

      await pumpEventQueue();

      expect(repo.consumeWalletDeleted(), isTrue);
      expect(repo.consumeWalletDeleted(), isFalse);
    });
  });

  group("WalletDeletedConfirmation", () {
    testWidgets("confirms the deletion in English after a wipe", (
      tester,
    ) async {
      final repo = await repository();
      addTearDown(repo.close);
      repo.bridgedDispatch(ClearAllDataEvent());

      await pumpConfirmation(tester, repo: repo);

      expect(find.byType(IrmaDialog), findsOneWidget);
      expect(find.text(englishTitle), findsOneWidget);
      expect(find.text(englishBody), findsOneWidget);
    });

    testWidgets("confirms the deletion in Dutch after a wipe", (tester) async {
      final repo = await repository();
      addTearDown(repo.close);
      repo.bridgedDispatch(ClearAllDataEvent());

      await pumpConfirmation(tester, repo: repo, locale: const Locale("nl"));

      expect(find.text(dutchTitle), findsOneWidget);
      expect(find.text(dutchBody), findsOneWidget);
    });

    testWidgets("stays open until the user dismisses it", (tester) async {
      final repo = await repository();
      addTearDown(repo.close);
      repo.bridgedDispatch(ClearAllDataEvent());

      await pumpConfirmation(tester, repo: repo);
      await tester.pump(const Duration(seconds: 30));

      expect(find.byType(IrmaDialog), findsOneWidget);

      await tester.tap(find.text("OK"));
      await tester.pumpAndSettle();

      expect(find.byType(IrmaDialog), findsNothing);
    });

    testWidgets("shows nothing on a fresh enrollment", (tester) async {
      final repo = await repository();
      addTearDown(repo.close);

      await pumpConfirmation(tester, repo: repo);

      expect(find.byType(IrmaDialog), findsNothing);
    });
  });
}
