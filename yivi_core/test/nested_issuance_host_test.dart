import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/providers/nested_issuance_host_provider.dart";

class _Host implements NestedIssuanceHost {
  @override
  final int underlyingSessionId;
  final attached = <int>[];

  _Host(this.underlyingSessionId);

  @override
  void attach(int sessionId) => attached.add(sessionId);
}

void main() {
  final host = _Host(1);
  bool active(int id) => id == 1;

  test("a session started while its request waits goes to the host", () {
    expect(
      hostForNewSession(
        host,
        hasUnderlying: true,
        replacing: false,
        isActive: active,
      ),
      host,
    );
  });

  test("otherwise it gets its own session screen", () {
    // No host, no waiting request, a replacing session, another request.
    expect(
      hostForNewSession(
        null,
        hasUnderlying: true,
        replacing: false,
        isActive: active,
      ),
      isNull,
    );
    expect(
      hostForNewSession(
        host,
        hasUnderlying: false,
        replacing: false,
        isActive: active,
      ),
      isNull,
    );
    expect(
      hostForNewSession(
        host,
        hasUnderlying: true,
        replacing: true,
        isActive: active,
      ),
      isNull,
    );
    expect(
      hostForNewSession(
        _Host(2),
        hasUnderlying: true,
        replacing: false,
        isActive: active,
      ),
      isNull,
    );
  });

  test("a host only unregisters itself", () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(nestedIssuanceHostProvider.notifier);
    final first = _Host(1), second = _Host(1);
    notifier.register(first);
    notifier.register(second);
    notifier.unregister(first);
    expect(container.read(nestedIssuanceHostProvider), second);
    notifier.unregister(second);
    expect(container.read(nestedIssuanceHostProvider), isNull);
  });
}
