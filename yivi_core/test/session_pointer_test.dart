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

  group("OpenID4VC scheme URI", () {
    test("openid4vp:// produces a disclosing openid4vp SessionPointer", () {
      const content =
          "openid4vp://?request_uri=https://verifier.example/req/abc&client_id=x509_san_dns:verifier.example";
      final pointer = Pointer.fromString(content) as SessionPointer;
      expect(pointer.protocol, Protocol.openid4vp);
      expect(pointer.irmaqr, "disclosing");
      expect(pointer.u, content);
    });

    // eudi-openid4vp:// is an EUDI Wallet / HAIP-profile alias, not in the
    // OpenID4VP spec itself. Yivi accepts it for EUDI compatibility.
    test("eudi-openid4vp:// is treated the same as openid4vp://", () {
      const content =
          "eudi-openid4vp://?request_uri=https://verifier.example/req/abc&client_id=x509_san_dns:verifier.example&state=xyz";
      final pointer = Pointer.fromString(content) as SessionPointer;
      expect(pointer.protocol, Protocol.openid4vp);
      expect(pointer.irmaqr, "disclosing");
      expect(pointer.u, content);
    });

    test(
      "openid-credential-offer:// with credential_offer_uri produces an issuing openid4vci SessionPointer",
      () {
        const content =
            "openid-credential-offer://?credential_offer_uri=https://issuer.example/offer/123";
        final pointer = Pointer.fromString(content) as SessionPointer;
        expect(pointer.protocol, Protocol.openid4vci);
        expect(pointer.irmaqr, "issuing");
        expect(pointer.u, content);
      },
    );

    test(
      "openid-credential-offer:// with inline credential_offer is also accepted",
      () {
        const content =
            'openid-credential-offer://?credential_offer={"credential_issuer":"https://issuer.example","credential_configuration_ids":["UniversityDegree_JWT"]}';
        final pointer = Pointer.fromString(content) as SessionPointer;
        expect(pointer.protocol, Protocol.openid4vci);
        expect(pointer.irmaqr, "issuing");
        expect(pointer.u, content);
      },
    );

    test("missing client_id on openid4vp:// throws MissingPointer", () {
      expect(
        () => Pointer.fromString(
          "openid4vp://?request_uri=https://verifier.example/req/abc",
        ),
        throwsA(isA<MissingPointer>()),
      );
    });

    test("missing request_uri on openid4vp:// throws MissingPointer", () {
      expect(
        () => Pointer.fromString(
          "openid4vp://?client_id=x509_san_dns:verifier.example",
        ),
        throwsA(isA<MissingPointer>()),
      );
    });

    test(
      "missing both credential_offer params on openid-credential-offer:// throws MissingPointer",
      () {
        expect(
          () => Pointer.fromString("openid-credential-offer://?foo=bar"),
          throwsA(isA<MissingPointer>()),
        );
      },
    );
  });

  group("OpenID4VC universal link", () {
    test("openid4vp universal link produces canonical openid4vp:// pointer", () {
      const requestUri = "https://verifier.example/req/abc";
      const clientId = "x509_san_dns:verifier.example";
      final pointer =
          Pointer.fromString(
                "https://open.yivi.app/-/openid4vp?request_uri=$requestUri&client_id=$clientId",
              )
              as SessionPointer;
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
        final pointer =
            Pointer.fromString(
                  "https://open.yivi.app/-/openid-credential-offer?credential_offer_uri=$offerUri",
                )
                as SessionPointer;
        expect(pointer.protocol, Protocol.openid4vci);
        expect(pointer.irmaqr, "issuing");
        expect(
          pointer.u,
          "openid-credential-offer://?credential_offer_uri=$offerUri",
        );
      },
    );

    test("staging host is accepted", () {
      const requestUri = "https://verifier.example/req/abc";
      const clientId = "x509_san_dns:verifier.example";
      final pointer =
          Pointer.fromString(
                "https://open.staging.yivi.app/-/openid4vp?request_uri=$requestUri&client_id=$clientId",
              )
              as SessionPointer;
      expect(pointer.protocol, Protocol.openid4vp);
      expect(
        pointer.u,
        "openid4vp://?request_uri=$requestUri&client_id=$clientId",
      );
    });

    test(
      "missing request_uri on openid4vp universal link throws MissingPointer",
      () {
        expect(
          () => Pointer.fromString(
            "https://open.yivi.app/-/openid4vp?client_id=x509_san_dns:verifier.example",
          ),
          throwsA(isA<MissingPointer>()),
        );
      },
    );

    test(
      "missing client_id on openid4vp universal link throws MissingPointer",
      () {
        expect(
          () => Pointer.fromString(
            "https://open.yivi.app/-/openid4vp?request_uri=https://verifier.example/req/abc",
          ),
          throwsA(isA<MissingPointer>()),
        );
      },
    );

    test(
      "missing both credential_offer params on openid-credential-offer universal link throws MissingPointer",
      () {
        expect(
          () => Pointer.fromString(
            "https://open.yivi.app/-/openid-credential-offer?foo=bar",
          ),
          throwsA(isA<MissingPointer>()),
        );
      },
    );

    test("unknown query params are preserved verbatim into synthesized URI", () {
      const requestUri = "https://verifier.example/req/abc";
      const clientId = "x509_san_dns:verifier.example";
      final pointer =
          Pointer.fromString(
                "https://open.yivi.app/-/openid4vp?request_uri=$requestUri&client_id=$clientId&state=xyz&nonce=n1&utm_source=email",
              )
              as SessionPointer;
      expect(
        pointer.u,
        "openid4vp://?request_uri=$requestUri&client_id=$clientId&state=xyz&nonce=n1&utm_source=email",
      );
    });

    test("look-alike host is not treated as a universal link", () {
      expect(
        () => Pointer.fromString(
          "https://open.yivi.app.evil.com/-/openid4vp?request_uri=https://verifier.example/req/abc&client_id=x509_san_dns:verifier.example",
        ),
        throwsA(isA<MissingPointer>()),
      );
    });

    test("path that is a prefix-match only is not treated as a universal link", () {
      expect(
        () => Pointer.fromString(
          "https://open.yivi.app/-/openid4vp-but-not-really?request_uri=https://verifier.example/req/abc&client_id=x509_san_dns:verifier.example",
        ),
        throwsA(isA<MissingPointer>()),
      );
      expect(
        () => Pointer.fromString(
          "https://open.yivi.app/-/openid4vp/extra?request_uri=https://verifier.example/req/abc&client_id=x509_san_dns:verifier.example",
        ),
        throwsA(isA<MissingPointer>()),
      );
    });

    test("existing IRMA https://open.yivi.app/-/session#... still parses", () {
      const url = "https://example.com/session/abc";
      const irmaQr = "disclosing";
      final pointer =
          Pointer.fromString(
                'https://open.yivi.app/-/session#{"u":"$url","irmaqr":"$irmaQr"}',
              )
              as SessionPointer;
      expect(pointer.u, url);
      expect(pointer.irmaqr, irmaQr);
    });
  });

  // Regression for #651: yivi-frontend-packages stamps the second-device flag
  // as camelCase `continueOnSecondDevice`, but the app parses the snake
  // `continue_on_second_device` key. A camera-app scan of a desktop QR reaches
  // the wallet through the universal-link/scheme path (not the in-app scanner,
  // which force-sets the flag), so the dropped camelCase read silently ran the
  // same-device terminal flow for a second-device session.
  group("continueOnSecondDevice casing (#651)", () {
    const url = "https://example.com/session/abc";
    const irmaQr = "disclosing";

    test("camelCase flag on universal link is read as second-device", () {
      final pointer =
          Pointer.fromString(
                'https://open.yivi.app/-/session#{"u":"$url","irmaqr":"$irmaQr","continueOnSecondDevice":true}',
              )
              as SessionPointer;
      expect(pointer.continueOnSecondDevice, isTrue);
    });

    test("camelCase flag via irma://qr/json carrier is read (shared branch)", () {
      final pointer =
          Pointer.fromString(
                'irma://qr/json/{"u":"$url","irmaqr":"$irmaQr","continueOnSecondDevice":true}',
              )
              as SessionPointer;
      expect(pointer.continueOnSecondDevice, isTrue);
    });

    test("snake_case flag still parses (irmago bridge casing)", () {
      final pointer =
          Pointer.fromString(
                'https://open.yivi.app/-/session#{"u":"$url","irmaqr":"$irmaQr","continue_on_second_device":true}',
              )
              as SessionPointer;
      expect(pointer.continueOnSecondDevice, isTrue);
    });

    test("no flag (mobile button payload) defaults to same-device", () {
      final pointer =
          Pointer.fromString(
                'https://open.yivi.app/-/session#{"u":"$url","irmaqr":"$irmaQr"}',
              )
              as SessionPointer;
      expect(pointer.continueOnSecondDevice, isFalse);
    });

    test("when both keys present the explicit snake value wins", () {
      final pointer =
          Pointer.fromString(
                'https://open.yivi.app/-/session#{"u":"$url","irmaqr":"$irmaQr","continue_on_second_device":false,"continueOnSecondDevice":true}',
              )
              as SessionPointer;
      expect(pointer.continueOnSecondDevice, isFalse);
    });

    test("camelCase flag on a wizard-session payload is read", () {
      final pointer =
          Pointer.fromString(
                'https://open.yivi.app/-/session#{"wizard":"test","u":"$url","irmaqr":"$irmaQr","continueOnSecondDevice":true}',
              )
              as SessionPointer;
      expect(pointer.continueOnSecondDevice, isTrue);
    });
  });
}
