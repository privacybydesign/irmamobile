import "package:flutter_test/flutter_test.dart";

import "package:yivi_core/src/models/irma_configuration.dart";
import "package:yivi_core/src/models/translated_value.dart";
import "package:yivi_core/src/util/reissue_resolver.dart";

CredentialType _credentialType(String id, {TranslatedValue? issueUrl}) {
  final parts = id.split(".");
  return CredentialType(
    id: parts.last,
    name: const TranslatedValue.empty(),
    issuerId: parts.length > 1 ? parts[1] : "issuer",
    schemeManagerId: parts.first,
    isSingleton: false,
    description: const TranslatedValue.empty(),
    issueUrl: issueUrl ?? const TranslatedValue.empty(),
  );
}

IrmaConfiguration _config(Map<String, CredentialType> credentialTypes) =>
    IrmaConfiguration(
      schemeManagers: const {},
      requestorSchemes: const {},
      requestors: const {},
      issuers: const {},
      credentialTypes: credentialTypes,
      attributeTypes: const {},
      issueWizards: const {},
      path: "",
    );

void main() {
  group("resolveReissue", () {
    const credId = "pbdf.pbdf.email";

    test(
      "uses the configuration's issue url when the credential type exists",
      () {
        final config = _config({
          credId: _credentialType(
            credId,
            issueUrl: TranslatedValue({"en": "https://example.com/issue"}),
          ),
        });

        final result = resolveReissue(
          credentialId: credId,
          fallbackIssueUrl: TranslatedValue({
            "en": "https://stale.example/old",
          }),
          irmaConfiguration: config,
          languageCode: "en",
        );

        expect(result, isA<ReissueAvailable>());
        expect((result as ReissueAvailable).url, "https://example.com/issue");
      },
    );

    test(
      "redirects to the newer endpoint when the scheme replaced the issue url",
      () {
        // The held credential still points at the removed (404) endpoint, but the
        // configuration has been updated to a newer one. The updated URL wins.
        final config = _config({
          credId: _credentialType(
            credId,
            issueUrl: TranslatedValue({"en": "https://example.com/v2/issue"}),
          ),
        });

        final result = resolveReissue(
          credentialId: credId,
          fallbackIssueUrl: TranslatedValue({
            "en": "https://example.com/v1/issue",
          }),
          irmaConfiguration: config,
          languageCode: "en",
        );

        expect(result, isA<ReissueAvailable>());
        expect(
          (result as ReissueAvailable).url,
          "https://example.com/v2/issue",
        );
      },
    );

    test(
      "is unavailable when the credential type was removed from the scheme",
      () {
        final config = _config({
          "pbdf.pbdf.other": _credentialType(
            "pbdf.pbdf.other",
            issueUrl: TranslatedValue({"en": "https://example.com/issue"}),
          ),
        });

        final result = resolveReissue(
          credentialId: credId,
          fallbackIssueUrl: TranslatedValue({
            "en": "https://stale.example/old",
          }),
          irmaConfiguration: config,
          languageCode: "en",
        );

        expect(result, isA<ReissueUnavailable>());
      },
    );

    test("is unavailable when the credential type exists but no longer has an "
        "issue url", () {
      final config = _config({credId: _credentialType(credId)});

      final result = resolveReissue(
        credentialId: credId,
        fallbackIssueUrl: TranslatedValue({"en": "https://stale.example/old"}),
        irmaConfiguration: config,
        languageCode: "en",
      );

      expect(result, isA<ReissueUnavailable>());
    });

    test("falls back to the stored url when configuration is not loaded", () {
      final result = resolveReissue(
        credentialId: credId,
        fallbackIssueUrl: TranslatedValue({"en": "https://stored.example/old"}),
        irmaConfiguration: null,
        languageCode: "en",
      );

      expect(result, isA<ReissueAvailable>());
      expect((result as ReissueAvailable).url, "https://stored.example/old");
    });

    test(
      "is unavailable when configuration is not loaded and there is no stored "
      "url",
      () {
        final result = resolveReissue(
          credentialId: credId,
          fallbackIssueUrl: const TranslatedValue.empty(),
          irmaConfiguration: null,
          languageCode: "en",
        );

        expect(result, isA<ReissueUnavailable>());
      },
    );
  });
}
