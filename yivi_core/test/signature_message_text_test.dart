import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/util/signature_message_text.dart";

void main() {
  String stripBreaks(String s) => s.replaceAll(zeroWidthSpace, "");

  group("insertSoftBreaks", () {
    test("leaves short and well-spaced text untouched", () {
      const message = "Message to be signed by user";
      expect(insertSoftBreaks(message), message);
    });

    test("leaves whitespace-separated words untouched", () {
      final message = List.filled(1000, "123456789").join(" ");
      expect(insertSoftBreaks(message), message);
    });

    test("inserts break opportunities into a long unbroken run", () {
      final message = "0" * (64 * 1000);
      final result = insertSoftBreaks(message);

      // The visible content is unchanged: zero-width spaces are invisible.
      expect(stripBreaks(result), message);

      // Break opportunities are inserted so the layout engine never has to
      // break a single huge "word", which is what froze the UI in issue #294.
      expect(result.contains(zeroWidthSpace), isTrue);
      final runs = result.split(zeroWidthSpace).where((run) => run.isNotEmpty);
      expect(runs.every((run) => run.length <= maxUnbrokenRunLength), isTrue);
    });

    test("does not break exactly at the run limit", () {
      final message = "0" * maxUnbrokenRunLength;
      expect(insertSoftBreaks(message), message);
    });

    test("breaks once just past the run limit", () {
      final message = "0" * (maxUnbrokenRunLength + 1);
      final result = insertSoftBreaks(message);
      expect(stripBreaks(result), message);
      expect(zeroWidthSpace.allMatches(result).length, 1);
    });
  });

  group("signatureMessagePreview / truncation", () {
    test("short message is not truncated", () {
      const message = "hello";
      expect(signatureMessageIsTruncated(message), isFalse);
      expect(signatureMessagePreview(message), message);
    });

    test("long message is truncated to the preview limit", () {
      final message = "a" * (maxInlineSignatureMessageLength + 100);
      expect(signatureMessageIsTruncated(message), isTrue);
      expect(
        signatureMessagePreview(message).length,
        maxInlineSignatureMessageLength,
      );
    });

    test("message exactly at the limit is not truncated", () {
      final message = "a" * maxInlineSignatureMessageLength;
      expect(signatureMessageIsTruncated(message), isFalse);
      expect(signatureMessagePreview(message), message);
    });
  });

  group("renderableSignatureMessage", () {
    test("collapsed render of a huge message is bounded and broken", () {
      final message = "0" * (64 * 1000);
      final collapsed = renderableSignatureMessage(message);

      // Bounded length: preview limit plus the inserted zero-width spaces.
      expect(stripBreaks(collapsed).length, maxInlineSignatureMessageLength);
      expect(collapsed.contains(zeroWidthSpace), isTrue);
    });

    test("expanded render keeps the full (soft-broken) message", () {
      final message = "0" * (64 * 1000);
      final expanded = renderableSignatureMessage(message, expanded: true);
      expect(stripBreaks(expanded), message);
    });
  });
}
