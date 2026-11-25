import "dart:io" show HttpStatus;

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_riverpod/misc.dart" show Override, ProviderListenable;
import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/keyshare_email_link_api.dart";
import "package:yivi_core/src/models/credential.dart";
import "package:yivi_core/src/models/protocol.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/providers/credentials_provider.dart";
import "package:yivi_core/src/providers/email_linking_provider.dart";
import "package:yivi_core/src/providers/preferences_provider.dart";
import "package:yivi_core/src/screens/add_data/secure_app.dart";

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

  /// Whether the keyshare server's link endpoint is known.
  var linkingOffered = false;

  setUpAll(() => SharedPreferences.setMockInitialValues({}));

  setUp(() async {
    prefs = await IrmaPreferences.fromInstance(
      mostRecentTermsUrlNl: "",
      mostRecentTermsUrlEn: "",
    );
    await prefs.clearAll();
    linkingOffered = false;
  });

  // Most tests are about an install that already holds a credential, where
  // "Finish setting up Yivi" may show.
  ProviderContainer newContainer([
    List<Override> overrides = const [],
    bool hasCredentials = true,
  ]) {
    final container = ProviderContainer(
      overrides: [
        preferencesProvider.overrideWithValue(prefs),
        hasCredentialsProvider.overrideWithValue(hasCredentials),
        emailLinkingOfferedProvider.overrideWithValue(linkingOffered),
        ...overrides,
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  // The preferences stream their values, so a provider reads as unloaded until
  // the event queue has run.
  Future<bool> read(
    ProviderContainer container,
    ProviderListenable<bool> provider,
  ) async {
    final subscription = container.listen(provider, (_, _) {});
    await pumpEventQueue();
    final value = subscription.read();
    subscription.close();
    return value;
  }

  group("Finish setting up Yivi (More)", () {
    test("is not there while linking is not offered", () async {
      expect(await read(newContainer(), setupUnfinishedProvider), isFalse);
    });

    test("shows when offered, with data, and nothing linked", () async {
      linkingOffered = true;

      expect(await read(newContainer(), setupUnfinishedProvider), isTrue);
    });

    test("waits for the first credential", () async {
      linkingOffered = true;

      expect(
        await read(newContainer(const [], false), setupUnfinishedProvider),
        isFalse,
      );
    });

    test(
      "goes once an address is linked, and so does the settings entry",
      () async {
        linkingOffered = true;
        await prefs.emailLinked.set(true);
        final container = newContainer();

        expect(await read(container, setupUnfinishedProvider), isFalse);
        expect(await read(container, emailLinkAvailableProvider), isFalse);
      },
    );

    test("is wiped with the other preferences", () async {
      await prefs.emailLinked.set(true);
      await prefs.secureOfferShown.set(true);

      await prefs.clearAll();

      expect(await prefs.emailLinked.stream.first, isFalse);
      expect(await prefs.secureOfferShown.stream.first, isFalse);
    });
  });

  group("EmailLinking", () {
    test("tracks the disclosure session", () {
      final container = newContainer();
      final linking = container.read(emailLinkingProvider.notifier);

      linking.trackDisclosure(4);
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

      expect(await prefs.emailLinked.stream.first, isTrue);
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

  group("which Success offers to secure the app", () {
    Credential card(String id) => Credential(
      credentialId: id,
      hash: id,
      name: id,
      issuer: TrustedParty(
        id: "i",
        name: "Issuer",
        url: null,
        parent: null,
        verified: true,
      ),
      credentialInstanceIds: const {},
      batchInstanceCountsRemaining: const {},
      attributes: const [],
      revoked: false,
      revocationSupported: false,
      issueUrl: null,
    );
    final address = card("pbdf.gemeente.address");
    final email = card("pbdf.sidn-pbdf.email");

    SecureOfferKind? offer(
      List<Credential> cards, {
      bool linking = false,
      bool available = true,
      bool hadCards = false,
      bool shownBefore = false,
    }) => secureOfferFor(
      cards: cards,
      linking: linking,
      available: available,
      hadCards: hadCards,
      shownBefore: shownBefore,
    );

    test("the first card added in the app, once", () {
      expect(offer([address]), SecureOfferKind.firstCard);
      expect(offer([address], shownBefore: true), isNull);
      expect(offer([address], hadCards: true), isNull);
    });

    test("an e-mail card, also later and after the first offer", () {
      expect(offer([email]), SecureOfferKind.emailCard);
      expect(
        offer([email], hadCards: true, shownBefore: true),
        SecureOfferKind.emailCard,
      );
    });

    test("nothing while linking is not available, while linking, or for "
        "several cards", () {
      expect(offer([email], available: false), isNull);
      expect(offer([address], available: false), isNull);
      expect(offer([email], linking: true), isNull);
      expect(offer([address, email]), isNull);
    });
  });
}
