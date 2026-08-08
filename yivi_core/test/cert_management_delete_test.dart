import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/irma_bridge.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/certificate_events.dart";
import "package:yivi_core/src/models/eudi_configuration.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/screens/debug/cert_management/cert_management_screen.dart";
import "package:yivi_core/src/theme/theme.dart";

// Regression test for #700: the debug certificate management screen could
// install certificates but had no way to remove them. Deleteable certificates
// (the top-level cert of each installed chain) must show a delete button that
// dispatches a RemoveCertificateEvent with the certificate's thumbprint.

class _RecordingBridge extends IrmaBridge {
  final dispatched = <Event>[];

  @override
  void dispatch(Event event) {
    dispatched.add(event);
  }

  void emit(Event event) => addEvent(event);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<IrmaRepository> repository(_RecordingBridge bridge) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await IrmaPreferences.fromInstance(
      mostRecentTermsUrlNl: "",
      mostRecentTermsUrlEn: "",
    );
    return IrmaRepository(client: bridge, preferences: preferences);
  }

  Future<void> pumpScreen(WidgetTester tester, IrmaRepository repo) async {
    final widget = IrmaRepositoryProvider(
      repository: repo,
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
          home: CertificateManagementScreen(),
        ),
      ),
    );

    // FileTranslationLoader reads the locale JSON with real IO, which the test
    // framework's fake clock does not drive: without runAsync plus a real
    // delay, Localizations never rebuilds and the tree stays empty.
    await tester.runAsync(() async {
      await tester.pumpWidget(widget);
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    // No pumpAndSettle here: the screen shows a progress spinner until the
    // EudiConfiguration stream emits, and a spinner never settles.
    await tester.pump();
  }

  // Delivers [event] through the bridge and pumps until the rebuilt list is
  // on screen. The stream event crosses an async boundary, so a single pump
  // is not enough.
  Future<void> emitAndPump(
    WidgetTester tester,
    _RecordingBridge bridge,
    Event event,
  ) async {
    await tester.runAsync(() async {
      bridge.emit(event);
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
  }

  testWidgets("delete button dispatches RemoveCertificateEvent", (
    tester,
  ) async {
    final bridge = _RecordingBridge();
    final repo = await repository(bridge);
    addTearDown(repo.close);

    await pumpScreen(tester, repo);

    await emitAndPump(
      tester,
      bridge,
      EudiConfigurationEvent(
        eudiConfiguration: EudiConfiguration(
          issuerCertificates: [
            Cert(
              thumbprint: "aabbcc",
              subject: "Deleteable Issuer",
              deleteable: true,
            ),
            Cert(thumbprint: "112233", subject: "Fixed Issuer"),
          ],
          verifierCertificates: [
            Cert(
              thumbprint: "ddeeff",
              subject: "Deleteable Verifier",
              deleteable: true,
            ),
          ],
        ),
      ),
    );

    expect(find.text("Deleteable Issuer"), findsOneWidget);
    expect(find.text("Fixed Issuer"), findsOneWidget);
    expect(find.text("Deleteable Verifier"), findsOneWidget);

    // Only the deleteable certificates get a delete button.
    expect(find.byIcon(Icons.delete), findsNWidgets(2));

    // The issuer section is listed first, so the first delete button belongs
    // to the deleteable issuer certificate.
    await tester.tap(find.byIcon(Icons.delete).first);
    await tester.pump();

    final removeEvents = bridge.dispatched.whereType<RemoveCertificateEvent>();
    expect(removeEvents, hasLength(1));
    expect(removeEvents.single.type, "issuer");
    expect(removeEvents.single.thumbprint, "aabbcc");
  });

  testWidgets("verifier delete button sends the verifier type", (tester) async {
    final bridge = _RecordingBridge();
    final repo = await repository(bridge);
    addTearDown(repo.close);

    await pumpScreen(tester, repo);

    await emitAndPump(
      tester,
      bridge,
      EudiConfigurationEvent(
        eudiConfiguration: EudiConfiguration(
          issuerCertificates: [],
          verifierCertificates: [
            Cert(
              thumbprint: "ddeeff",
              subject: "Deleteable Verifier",
              deleteable: true,
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pump();

    final removeEvents = bridge.dispatched.whereType<RemoveCertificateEvent>();
    expect(removeEvents, hasLength(1));
    expect(removeEvents.single.type, "verifier");
    expect(removeEvents.single.thumbprint, "ddeeff");
  });
}
