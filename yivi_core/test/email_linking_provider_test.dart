import "dart:io" show HttpStatus;

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_riverpod/misc.dart" show Override;
import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/feature_flags.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/models/email_code_pointer.dart";
import "package:yivi_core/src/models/protocol.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/providers/email_linking_provider.dart";
import "package:yivi_core/src/providers/preferences_provider.dart";

class _FakeLinkApi implements KeyshareEmailLinkApi {
  int calls = 0;

  @override
  Future<SessionPointer> startSession() async {
    calls++;
    return SessionPointer(
      u: "https://keyshare.example/irma/session/abc",
      irmaqr: "disclosing",
      protocol: Protocol.irma,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late IrmaPreferences prefs;

  setUpAll(() => SharedPreferences.setMockInitialValues({}));

  setUp(() async {
    prefs = await IrmaPreferences.fromInstance(
      mostRecentTermsUrlNl: "",
      mostRecentTermsUrlEn: "",
    );
    await prefs.clearAll();
  });

  ProviderContainer newContainer([List<Override> overrides = const []]) {
    final container = ProviderContainer(
      overrides: [preferencesProvider.overrideWithValue(prefs), ...overrides],
    );
    addTearDown(container.dispose);
    return container;
  }

  // The preferences stream their values, so a provider reads as unloaded until
  // the event queue has run.
  Future<bool> readVisible(ProviderContainer container) async {
    final subscription = container.listen(
      emailBannerVisibleProvider,
      (_, _) {},
    );
    await pumpEventQueue();
    final visible = subscription.read();
    subscription.close();
    return visible;
  }

  group("banner on the Gegevens tab", () {
    test("is hidden while the flag is off", () async {
      expect(await readVisible(newContainer()), isFalse);
    });

    test("shows with the flag on and nothing linked or dismissed", () async {
      await prefs.setFeatureFlag(FeatureFlag.emailLinking, true);

      expect(await readVisible(newContainer()), isTrue);
    });

    test("is hidden once an address is linked", () async {
      await prefs.setFeatureFlag(FeatureFlag.emailLinking, true);
      await prefs.markEmailLinked();

      expect(await readVisible(newContainer()), isFalse);
    });

    test("is hidden until the snooze has passed", () async {
      await prefs.setFeatureFlag(FeatureFlag.emailLinking, true);

      await prefs.snoozeEmailBannerUntil(
        DateTime.now().add(const Duration(days: 1)),
      );
      expect(await readVisible(newContainer()), isFalse);

      await prefs.snoozeEmailBannerUntil(
        DateTime.now().subtract(const Duration(seconds: 1)),
      );
      expect(await readVisible(newContainer()), isTrue);
    });

    test("comes back when the snooze ends while the app stays open", () async {
      await prefs.setFeatureFlag(FeatureFlag.emailLinking, true);
      await prefs.snoozeEmailBannerUntil(
        DateTime.now().add(const Duration(milliseconds: 200)),
      );
      final container = newContainer();
      final subscription = container.listen(
        emailBannerVisibleProvider,
        (_, _) {},
      );
      await pumpEventQueue();
      expect(subscription.read(), isFalse);

      await Future<void>.delayed(const Duration(milliseconds: 400));

      expect(subscription.read(), isTrue);
    });

    test(
      "stays hidden after Negeren, even when the snooze has passed",
      () async {
        await prefs.setFeatureFlag(FeatureFlag.emailLinking, true);
        await prefs.snoozeEmailBannerUntil(
          DateTime.now().subtract(const Duration(days: 30)),
        );
        await prefs.dismissEmailBanner();

        expect(await readVisible(newContainer()), isFalse);
      },
    );

    test(
      "the settings entry stays available after the banner is gone",
      () async {
        await prefs.setFeatureFlag(FeatureFlag.emailLinking, true);
        await prefs.dismissEmailBanner();
        final container = newContainer();
        final subscription = container.listen(
          emailLinkAvailableProvider,
          (_, _) {},
        );
        await pumpEventQueue();

        expect(subscription.read(), isTrue);
      },
    );

    test("the settings entry is gone once an address is linked", () async {
      await prefs.setFeatureFlag(FeatureFlag.emailLinking, true);
      await prefs.markEmailLinked();
      final container = newContainer();
      final subscription = container.listen(
        emailLinkAvailableProvider,
        (_, _) {},
      );
      await pumpEventQueue();

      expect(subscription.read(), isFalse);
    });

    test("is wiped with the other preferences", () async {
      await prefs.markEmailLinked();
      await prefs.dismissEmailBanner();
      await prefs.snoozeEmailBannerUntil(DateTime.now());

      await prefs.clearAll();

      expect(await prefs.getEmailLinked().first, isFalse);
      expect(await prefs.getEmailBannerDismissed().first, isFalse);
      expect(
        (await prefs.getEmailBannerSnoozedUntil().first).millisecondsSinceEpoch,
        0,
      );
    });
  });

  group("EmailLinking", () {
    test("snoozes the banner by the snooze duration", () async {
      final container = newContainer();
      final before = DateTime.now();

      await container.read(emailLinkingProvider.notifier).snoozeBanner();

      final until = await prefs.getEmailBannerSnoozedUntil().first;
      expect(
        until.isAfter(before.add(emailBannerSnoozeDuration)) ||
            until.isAtSameMomentAs(before.add(emailBannerSnoozeDuration)),
        isTrue,
      );
      expect(
        until.isBefore(
          DateTime.now()
              .add(emailBannerSnoozeDuration)
              .add(const Duration(seconds: 1)),
        ),
        isTrue,
      );
      expect(await prefs.getEmailBannerDismissed().first, isFalse);
    });

    test("Negeren dismisses the banner for good", () async {
      final container = newContainer();

      await container.read(emailLinkingProvider.notifier).dismissBanner();

      expect(await prefs.getEmailBannerDismissed().first, isTrue);
    });

    test("tracks the issuance and then the disclosure session", () {
      final container = newContainer();
      final linking = container.read(emailLinkingProvider.notifier);

      linking.trackIssuance(3);
      expect(container.read(emailLinkingProvider).issuanceSessionId, 3);

      linking.trackDisclosure(4);
      expect(container.read(emailLinkingProvider).issuanceSessionId, isNull);
      expect(container.read(emailLinkingProvider).disclosureSessionId, 4);
    });

    test("hands a link over once", () {
      final container = newContainer();
      final linking = container.read(emailLinkingProvider.notifier);
      final link = EmailCodePointer(email: "jan@example.com", code: "ABC123");

      linking.receiveLink(link);

      expect(linking.takeLink(), same(link));
      expect(linking.takeLink(), isNull);
    });

    test("taking the link keeps the issuance session", () {
      final container = newContainer();
      final linking = container.read(emailLinkingProvider.notifier);

      linking.trackIssuance(3);
      linking.receiveLink(
        EmailCodePointer(email: "jan@example.com", code: "ABC123"),
      );
      linking.takeLink();

      expect(container.read(emailLinkingProvider).issuanceSessionId, 3);
    });

    test("starts the disclosure through the keyshare API", () async {
      final api = _FakeLinkApi();
      final container = newContainer([
        keyshareEmailLinkApiProvider.overrideWithValue(api),
      ]);

      final pointer = await container
          .read(emailLinkingProvider.notifier)
          .startDisclosure();

      expect(api.calls, 1);
      expect(pointer.irmaqr, "disclosing");
    });

    test("marks the address as linked", () async {
      final container = newContainer();

      await container.read(emailLinkingProvider.notifier).markLinked();

      expect(await prefs.getEmailLinked().first, isTrue);
    });
  });

  group("DefaultKeyshareEmailLinkApi", () {
    test("is unavailable until the endpoint is configured", () {
      expect(
        DefaultKeyshareEmailLinkApi(url: "").startSession(),
        throwsA(isA<KeyshareEmailLinkUnavailable>()),
      );
    });

    test("returns the session pointer from the session package", () async {
      final pointer = await http.runWithClient(
        () => DefaultKeyshareEmailLinkApi(
          url: "https://keyshare.example/email/link",
        ).startSession(),
        () => MockClient((request) async {
          expect(request.method, "POST");
          expect(request.url.toString(), "https://keyshare.example/email/link");
          return http.Response(
            '{"sessionPtr":{"u":"https://keyshare.example/irma/session/abc",'
            '"irmaqr":"disclosing"},"frontendRequest":{}}',
            HttpStatus.ok,
          );
        }),
      );

      expect(pointer.u, "https://keyshare.example/irma/session/abc");
      expect(pointer.irmaqr, "disclosing");
      expect(pointer.continueOnSecondDevice, isTrue);
    });

    test("fails on an error response", () {
      expect(
        http.runWithClient(
          () => DefaultKeyshareEmailLinkApi(
            url: "https://keyshare.example/email/link",
          ).startSession(),
          () => MockClient(
            (_) async => http.Response("nope", HttpStatus.internalServerError),
          ),
        ),
        throwsException,
      );
    });
  });
}
