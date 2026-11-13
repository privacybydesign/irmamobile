import "dart:async";
import "dart:io";

import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/yivi_core.dart";

/// Dart's network stack does not read Android's network security configuration
/// or iOS' App Transport Security. The zone the app runs in is what keeps it
/// from making a cleartext connection.
void main() {
  /// Opens a connection to [url] in the zone the app runs in.
  Future<void> open(String url) => runZoned(() async {
    final client = HttpClient();
    try {
      await client.openUrl("GET", Uri.parse(url));
    } finally {
      client.close(force: true);
    }
  }, zoneValues: appZoneValues);

  test("a cleartext connection from Dart is refused", () async {
    await expectLater(
      open("http://issuer.example.com/api"),
      throwsA(
        isA<UnsupportedError>().having(
          (e) => e.message,
          "message",
          contains("Non-https connection"),
        ),
      ),
    );
  });

  test("an https connection from Dart is not refused", () async {
    // Nothing listens on this port, so connecting fails. What matters is that
    // it gets as far as trying.
    await expectLater(
      open("https://localhost:9/"),
      throwsA(isA<SocketException>()),
    );
  });

  test("a cleartext connection to this device itself is allowed", () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));

    await open("http://localhost:${server.port}/");
  });
}
