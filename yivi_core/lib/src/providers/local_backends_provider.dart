import "package:flutter_riverpod/flutter_riverpod.dart";

import "preferences_provider.dart";

/// A backend setup on a developer's machine, to test server changes that are
/// not deployed yet. Set in the debug menu with the host only; every service
/// has a fixed port on it.
class LocalBackends {
  final String host;

  const LocalBackends(this.host);

  String get emailIssuer => "http://$host:8080";

  /// The keyshare e-mail link endpoint of myirmaserver (irmago#744).
  String get keyshareEmailLink => "http://$host:8081/email/link";
}

final _localBackendHostProvider = StreamProvider<String>(
  (ref) => ref.watch(preferencesProvider).getLocalBackendHost(),
);

/// Null unless a host is set in the debug menu.
final localBackendsProvider = Provider<LocalBackends?>((ref) {
  final host = ref.watch(_localBackendHostProvider).value?.trim() ?? "";
  return host.isEmpty ? null : LocalBackends(host);
});
