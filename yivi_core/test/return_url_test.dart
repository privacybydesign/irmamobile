import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/models/return_url.dart";

void main() {
  group("ReturnURL.parse", () {
    test("accepts web links, phone numbers and other apps' own schemes", () {
      for (final url in [
        "https://example.com/done",
        "http://example.com/done",
        "tel:+31612345678",
        "myapp://session/done",
      ]) {
        expect(ReturnURL.parse(url)?.toString(), url, reason: url);
      }
    });

    test("refuses schemes that run script, read local data or start an "
        "arbitrary Android component", () {
      for (final url in [
        "javascript:alert(1)",
        "JavaScript:alert(1)",
        "  javascript:alert(1)",
        "vbscript:msgbox(1)",
        "data:text/html,<script>alert(1)</script>",
        "blob:https://example.com/1",
        "about:blank",
        "file:///data/data/org.irmacard.cardemu/files/storageKey",
        "content://com.android.contacts/contacts",
        "intent://scan/#Intent;scheme=zxing;package=com.example;end",
        "android-app://com.example/https/example.com",
      ]) {
        expect(ReturnURL.parse(url), isNull, reason: url);
      }
    });

    test("has no return URL for nothing", () {
      expect(ReturnURL.parse(null), isNull);
      expect(ReturnURL.parse(""), isNull);
    });
  });

  group("ReturnURL.isInApp", () {
    test("opens an https link in the in-app browser when asked to", () {
      expect(ReturnURL.parse("https://example.com/?inapp")!.isInApp, isTrue);
      expect(ReturnURL.parse("https://example.com/")!.isInApp, isFalse);
    });

    test("never opens a cleartext link in the in-app browser", () {
      expect(ReturnURL.parse("http://example.com/?inapp")!.isInApp, isFalse);
    });
  });
}
