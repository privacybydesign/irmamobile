import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/models/email_code_pointer.dart";

void main() {
  test("reads the code and address from the fragment", () {
    final pointer = EmailCodePointer.tryParse(
      "https://open.yivi.app/-/email#code=ABC123&email=jan%40example.com",
    );

    expect(pointer, isNotNull);
    expect(pointer!.code, "ABC123");
    expect(pointer.email, "jan@example.com");
  });

  test("accepts the staging host", () {
    final pointer = EmailCodePointer.tryParse(
      "https://open.staging.yivi.app/-/email#code=ABC123&email=jan%40example.com",
    );

    expect(pointer, isNotNull);
  });

  test("upper-cases the code, as the verify screen does", () {
    final pointer = EmailCodePointer.tryParse(
      "https://open.yivi.app/-/email#code=abc123&email=jan%40example.com",
    );

    expect(pointer!.code, "ABC123");
  });

  test("ignores the code in the query string, which reaches server logs", () {
    expect(
      EmailCodePointer.tryParse(
        "https://open.yivi.app/-/email?code=ABC123&email=jan%40example.com",
      ),
      isNull,
    );
  });

  test("rejects links that are not the e-mail link", () {
    const fragment = "#code=ABC123&email=jan%40example.com";

    expect(
      EmailCodePointer.tryParse("https://example.com/-/email$fragment"),
      isNull,
    );
    expect(
      EmailCodePointer.tryParse("http://open.yivi.app/-/email$fragment"),
      isNull,
    );
    expect(
      EmailCodePointer.tryParse("https://open.yivi.app/-/session$fragment"),
      isNull,
    );
    expect(
      EmailCodePointer.tryParse("https://open.yivi.app/-/session#{}"),
      isNull,
    );
  });

  test("rejects a link without a usable code or address", () {
    const base = "https://open.yivi.app/-/email";

    expect(EmailCodePointer.tryParse(base), isNull);
    expect(EmailCodePointer.tryParse("$base#email=jan%40example.com"), isNull);
    expect(EmailCodePointer.tryParse("$base#code=ABC123"), isNull);
    expect(
      EmailCodePointer.tryParse("$base#code=ABC12&email=jan%40example.com"),
      isNull,
    );
    expect(
      EmailCodePointer.tryParse("$base#code=ABC123&email=not-an-address"),
      isNull,
    );
  });

  test("rejects a malformed fragment instead of throwing", () {
    expect(
      EmailCodePointer.tryParse("https://open.yivi.app/-/email#code=%ZZ"),
      isNull,
    );
  });
}
