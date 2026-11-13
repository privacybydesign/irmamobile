import "package:flutter_test/flutter_test.dart";
import "package:yivi/face_capture_webview.dart";

void main() {
  final captureUrl = Uri.parse("https://face.example.org/capture?session=1");

  test("the capture page and other pages of its site load", () {
    expect(staysOnCapturePage(captureUrl, captureUrl.toString()), isTrue);
    expect(
      staysOnCapturePage(captureUrl, "https://face.example.org/done"),
      isTrue,
    );
  });

  test("a navigation to another site is not followed", () {
    expect(
      staysOnCapturePage(captureUrl, "https://evil.example.com/capture"),
      isFalse,
    );
    expect(
      staysOnCapturePage(captureUrl, "https://face.example.org.evil.com/"),
      isFalse,
    );
  });

  test("anything but https is not followed", () {
    for (final url in [
      "http://face.example.org/capture",
      "file:///data/data/org.irmacard.cardemu/files/storageKey",
      "content://com.android.contacts/contacts",
      "intent://face.example.org/#Intent;scheme=https;end",
      "javascript:alert(1)",
      "not a url",
    ]) {
      expect(staysOnCapturePage(captureUrl, url), isFalse, reason: url);
    }
  });
}
