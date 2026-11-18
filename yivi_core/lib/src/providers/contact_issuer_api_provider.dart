import "package:flutter_riverpod/flutter_riverpod.dart";

import "../data/contact_issuer_api.dart";
import "../models/session.dart";
import "../util/value_holder.dart";
import "local_backends_provider.dart";

/// The e-mail issuer's base URL, set from the credential's issue URL when
/// adding or linking an address starts; null until then.
final emailIssuerUrlProvider = NotifierProvider(
  () => ValueHolder<String?>(null),
);

/// The SMS issuer's base URL, set like [emailIssuerUrlProvider].
final smsIssuerUrlProvider = NotifierProvider(() => ValueHolder<String?>(null));

/// The e-mail issuer: a debug local backend's, else the one set from the
/// credential's issue URL. Without either, nothing can be sent.
final emailIssuerApiProvider = Provider<ContactIssuerApi>((ref) {
  final host =
      ref.watch(localBackendsProvider)?.emailIssuer ??
      ref.watch(emailIssuerUrlProvider);
  return host == null ? const _NoIssuer() : EmailIssuerApi(host: host);
});

final smsIssuerApiProvider = Provider<ContactIssuerApi>((ref) {
  final host = ref.watch(smsIssuerUrlProvider);
  return host == null ? const _NoIssuer() : SmsIssuerApi(host: host);
});

/// No issuer set: every call fails, so the step says it could not send.
final class _NoIssuer implements ContactIssuerApi {
  const _NoIssuer();

  static Never _fail() => throw ContactFailed(StateError("no issuer set"));

  @override
  Future<void> send({required String target, required String language}) async =>
      _fail();

  @override
  Future<SessionPointer> verify({
    required String target,
    required String code,
  }) async => _fail();
}
