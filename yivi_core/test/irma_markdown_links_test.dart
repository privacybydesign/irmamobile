import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/widgets/irma_markdown.dart";

// Markdown can come from issuers (e.g. the FAQ in EUDI credential metadata), so
// IrmaMarkdown only opens https and mailto links.

void main() {
  test("opens https and mailto links", () {
    expect(isAllowedMarkdownLink("https://yivi.app/faq"), isTrue);
    expect(isAllowedMarkdownLink("HTTPS://yivi.app"), isTrue);
    expect(isAllowedMarkdownLink(" https://yivi.app "), isTrue);
    expect(isAllowedMarkdownLink("mailto:support@yivi.app"), isTrue);
  });

  test("ignores other schemes and scheme-less links", () {
    for (final href in [
      "http://example.com",
      "javascript:alert(1)",
      "file:///data/data/foundation.privacybydesign.irmamob/files",
      "intent://scan/#Intent;scheme=zxing;end",
      "tel:+31600000000",
      "yivi://session",
      "otherapp://do-something",
      "/relative/path",
      "example.com",
      "https:///no-host",
      "",
    ]) {
      expect(isAllowedMarkdownLink(href), isFalse, reason: href);
    }
  });
}
