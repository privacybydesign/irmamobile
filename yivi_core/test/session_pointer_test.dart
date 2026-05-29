import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/models/protocol.dart";
import "package:yivi_core/src/models/session.dart";

void main() {
  test("Create session pointer from URI", () {
    const url =
        "https://privacybydesign.foundation/tomcat/irma_api_server/api/v2/verification/DhimFIgKWVhGjBgUOihzIHKQsMMTDHIbULI0xEpWXAx";
    const irmaQr = "disclosing";
    final positiveTestCases = [
      'irma://qr/json/{"u":"$url","irmaqr":"$irmaQr"}',
      'https://irma.app/-pilot/session#{"u":"$url","irmaqr":"$irmaQr"}',
      'irma://qr/json/{"wizard":"test"}',
      'https://irma.app/-pilot/session#{"wizard":"test"}',
      'irma://qr/json/{"wizard":"test","u":"$url","irmaqr":"$irmaQr"}',
      'https://irma.app/-pilot/session#{"wizard":"test","u":"$url","irmaqr":"$irmaQr"}',
    ];

    for (final testCase in positiveTestCases) {
      final pointer = Pointer.fromString(testCase);
      if (testCase.contains("wizard")) {
        expect(pointer, isA<IssueWizardPointer>());
        final wizardPointer = pointer as IssueWizardPointer;
        expect(wizardPointer.wizard, "test");
      } else {
        expect(pointer, isNot(isA<IssueWizardPointer>()));
      }

      if (testCase.contains("irmaqr")) {
        expect(pointer, isA<SessionPointer>());
        final sessionPointer = pointer as SessionPointer;
        expect(sessionPointer.u, url);
        expect(sessionPointer.irmaqr, irmaQr);
      } else {
        expect(pointer, isNot(isA<SessionPointer>()));
      }
    }

    expect(
      () => Pointer.fromString("https://privacybydesign.foundation/"),
      throwsA(const TypeMatcher<MissingPointer>()),
    );
  });

  group("OpenID4VC universal link", () {
    test("openid4vp universal link produces canonical openid4vp:// pointer",
        () {
      const requestUri = "https://verifier.example/req/abc";
      const clientId = "verifier.example";
      final pointer = Pointer.fromString(
        "https://open.yivi.app/-/openid4vp?request_uri=$requestUri&client_id=$clientId",
      ) as SessionPointer;
      expect(pointer.protocol, Protocol.openid4vp);
      expect(pointer.irmaqr, "disclosing");
      expect(
        pointer.u,
        "openid4vp://?request_uri=$requestUri&client_id=$clientId",
      );
    });

    test(
        "openid-credential-offer universal link produces canonical openid-credential-offer:// pointer",
        () {
      const offerUri = "https://issuer.example/offer/123";
      final pointer = Pointer.fromString(
        "https://open.yivi.app/-/openid-credential-offer?credential_offer_uri=$offerUri",
      ) as SessionPointer;
      expect(pointer.protocol, Protocol.openid4vci);
      expect(pointer.irmaqr, "issuing");
      expect(
        pointer.u,
        "openid-credential-offer://?credential_offer_uri=$offerUri",
      );
    });

    test("staging host is accepted", () {
      const requestUri = "https://verifier.example/req/abc";
      const clientId = "verifier.example";
      final pointer = Pointer.fromString(
        "https://open.staging.yivi.app/-/openid4vp?request_uri=$requestUri&client_id=$clientId",
      ) as SessionPointer;
      expect(pointer.protocol, Protocol.openid4vp);
      expect(
        pointer.u,
        "openid4vp://?request_uri=$requestUri&client_id=$clientId",
      );
    });

    test("missing request_uri on openid4vp universal link throws MissingPointer",
        () {
      expect(
        () => Pointer.fromString(
          "https://open.yivi.app/-/openid4vp?client_id=verifier.example",
        ),
        throwsA(isA<MissingPointer>()),
      );
    });

    test("missing client_id on openid4vp universal link throws MissingPointer",
        () {
      expect(
        () => Pointer.fromString(
          "https://open.yivi.app/-/openid4vp?request_uri=https://verifier.example/req/abc",
        ),
        throwsA(isA<MissingPointer>()),
      );
    });

    test(
        "missing both credential_offer params on openid-credential-offer universal link throws MissingPointer",
        () {
      expect(
        () => Pointer.fromString(
          "https://open.yivi.app/-/openid-credential-offer?foo=bar",
        ),
        throwsA(isA<MissingPointer>()),
      );
    });

    test("unknown query params are preserved verbatim into synthesized URI",
        () {
      const requestUri = "https://verifier.example/req/abc";
      const clientId = "verifier.example";
      final pointer = Pointer.fromString(
        "https://open.yivi.app/-/openid4vp?request_uri=$requestUri&client_id=$clientId&state=xyz&nonce=n1&utm_source=email",
      ) as SessionPointer;
      expect(
        pointer.u,
        "openid4vp://?request_uri=$requestUri&client_id=$clientId&state=xyz&nonce=n1&utm_source=email",
      );
    });

    test("look-alike host is not treated as a universal link", () {
      expect(
        () => Pointer.fromString(
          "https://open.yivi.app.evil.com/-/openid4vp?request_uri=https://verifier.example/req/abc&client_id=verifier.example",
        ),
        throwsA(isA<MissingPointer>()),
      );
    });

    test("path that is a prefix-match only is not treated as a universal link",
        () {
      expect(
        () => Pointer.fromString(
          "https://open.yivi.app/-/openid4vp-but-not-really?request_uri=https://verifier.example/req/abc&client_id=verifier.example",
        ),
        throwsA(isA<MissingPointer>()),
      );
      expect(
        () => Pointer.fromString(
          "https://open.yivi.app/-/openid4vp/extra?request_uri=https://verifier.example/req/abc&client_id=verifier.example",
        ),
        throwsA(isA<MissingPointer>()),
      );
    });

    test("existing IRMA https://open.yivi.app/-/session#... still parses", () {
      const url = "https://example.com/session/abc";
      const irmaQr = "disclosing";
      final pointer = Pointer.fromString(
        'https://open.yivi.app/-/session#{"u":"$url","irmaqr":"$irmaQr"}',
      ) as SessionPointer;
      expect(pointer.u, url);
      expect(pointer.irmaqr, irmaQr);
    });
  });
}
