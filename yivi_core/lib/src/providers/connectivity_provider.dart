import "package:connectivity_plus/connectivity_plus.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

/// Abstraction over the platform connectivity lookup so the offline gate can
/// be driven by a fake in tests.
///
/// [isOnline]/[onlineChanges] report a coarse "has a network interface"
/// signal (wifi / mobile / ethernet / vpn present) — NOT a guarantee that the
/// internet is actually reachable. That's enough to catch the common
/// no-connection-at-all case before the PIN screen is shown (issue #618); a
/// PIN entered with no network can only fail against the keyshare server, and
/// a quickly-dismissed failure is indistinguishable from a wrong PIN.
abstract class ConnectivityService {
  /// The current connectivity, resolved once.
  Future<bool> isOnline();

  /// Emits `true`/`false` whenever the connectivity state changes.
  Stream<bool> get onlineChanges;
}

/// Default [ConnectivityService] backed by the `connectivity_plus` plugin.
class ConnectivityPlusService implements ConnectivityService {
  final Connectivity _connectivity;

  ConnectivityPlusService([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  static bool _hasConnection(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  @override
  Future<bool> isOnline() async =>
      _hasConnection(await _connectivity.checkConnectivity());

  @override
  Stream<bool> get onlineChanges =>
      _connectivity.onConnectivityChanged.map(_hasConnection);
}

/// Overridable in tests with a fake to drive the offline gate deterministically.
final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => ConnectivityPlusService(),
);

/// Whether the device currently has a network connection.
///
/// Starts by resolving the current state, then follows changes. Consumers
/// should treat a still-loading value as online (`.value ?? true`) so a slow
/// connectivity lookup on cold start never wrongly hides the PIN screen behind
/// the offline message.
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final service = ref.watch(connectivityServiceProvider);
  yield await service.isOnline();
  yield* service.onlineChanges;
});
