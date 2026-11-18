import "dart:io";

import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/data/irma_client_bridge.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/models/native_events.dart";
import "package:yivi_core/src/models/update_schemes_event.dart";

class _UnlistedEvent extends Event {}

/// Release builds are obfuscated, so the bridge must not derive an event's name
/// from its Dart class name. These tests pin the explicit names to what the Go
/// bridge and the native plugins switch on.
void main() {
  // Handled by the native plugins only; the Go bridge ignores them.
  const nativeOnly = {"AndroidSendToBackgroundEvent"};

  test("an outbound event is sent under its listed name", () {
    expect(
      IrmaClientBridge.outboundEventName(UpdateSchemesEvent()),
      "UpdateSchemesEvent",
    );
    expect(
      IrmaClientBridge.outboundEventName(AppReadyEvent(locale: "nl")),
      "AppReadyEvent",
    );
  });

  test("an event without a listed name is refused, not sent under its "
      "class name", () {
    expect(
      () => IrmaClientBridge.outboundEventName(_UnlistedEvent()),
      throwsStateError,
    );
  });

  test("the listed names are the class names", () {
    // Holds in this unobfuscated test build, and catches a typo in the table.
    IrmaClientBridge.outboundEventNames.forEach((type, name) {
      expect(name, type.toString());
    });
  });

  test("the outbound names are exactly the events the Go bridge handles", () {
    final source = File("irmagobridge/receive_event.go").readAsStringSync();
    final handledByGo = RegExp(
      r'case "(\w+)":',
    ).allMatches(source).map((m) => m.group(1)!).toSet();
    expect(handledByGo, isNotEmpty);

    final sentByDart = IrmaClientBridge.outboundEventNames.values.toSet();
    expect(sentByDart.difference(nativeOnly), handledByGo);
  });

  test("the events the native plugins send are known inbound names", () {
    expect(
      IrmaClientBridge.inboundEventNames,
      containsAll(["HandleURLEvent", "AppReadyAckEvent", "ErrorEvent"]),
    );
  });
}
