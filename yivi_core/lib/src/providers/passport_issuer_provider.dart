import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:vcmrtd/vcmrtd.dart";

import "./provider_helpers.dart" as helpers;

final passportIssuerUrlProvider = NotifierProvider(
  () => helpers.ValueNotifier("https://passport-issuer.staging.yivi.app"),
);

/// Hosts the passport issuer is allowed to hand the app an `irma_server_url`
/// for.
///
/// [DefaultPassportIssuer] posts the signed IRMA issuance request to the
/// `irma_server_url` the passport issuer returns, and refuses any host outside
/// this list. That JWT is not the raw chip scan: the data groups and EF.SOD go
/// to [passportIssuerUrlProvider] itself, which this list does not cover. It
/// does carry the attributes derived from the chip, including the facial
/// image. The IRMA server runs on a different host than the passport issuer,
/// so listing it explicitly is required: the constructor default is the host
/// of [passportIssuerUrlProvider], which never matches. Both environments are
/// listed because [passportIssuerUrlProvider] is set at runtime from the issue
/// URL in the scheme.
final allowedIrmaHostsProvider = Provider<Set<String>>(
  (ref) => const {"is.yivi.app", "is.staging.yivi.app"},
);

final passportIssuerProvider = Provider<PassportIssuer>(
  (ref) => DefaultPassportIssuer(
    hostName: ref.watch(passportIssuerUrlProvider),
    allowedIrmaHosts: ref.watch(allowedIrmaHostsProvider),
  ),
);

class ErrorThrowingPassportIssuer implements PassportIssuer {
  int startSessionCount = 0;
  final String errorToThrowOnIssuance;

  ErrorThrowingPassportIssuer({required this.errorToThrowOnIssuance});

  @override
  Future<NonceAndSessionId> startSessionAtPassportIssuer() async {
    startSessionCount += 1;
    return NonceAndSessionId(
      nonce: "d4e5f6a7d4e5f6a7",
      sessionId: "4f3c2a1b5e6d7c8f9a0b1c2d3e4f5a6b",
    );
  }

  @override
  Future<IrmaSessionPointer> startIrmaIssuanceSession(
    RawDocumentData passportDataResult,
    DocumentType documentType,
  ) async {
    throw Exception(errorToThrowOnIssuance);
  }

  @override
  Future<VerificationResponse> verifyPassport(
    RawDocumentData passportDataResult,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<VerificationResponse> verifyDrivingLicence(
    RawDocumentData drivingLicenceDataResult,
  ) {
    throw UnimplementedError();
  }
}
