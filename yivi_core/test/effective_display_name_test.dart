import "package:flutter_test/flutter_test.dart";

import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/translated_value.dart";

Attribute _attr({
  required List<dynamic> claimPath,
  required TranslatedValue displayName,
}) => Attribute(claimPath: claimPath, displayName: displayName);

void main() {
  group("Attribute.effectiveDisplayName", () {
    test("returns displayName when it has translations", () {
      final dn = TranslatedValue({"en": "Birthdate", "nl": "Geboortedatum"});
      final attr = _attr(claimPath: const ["dob"], displayName: dn);
      expect(attr.effectiveDisplayName, same(dn));
    });

    test(
      "falls back to last string segment of claimPath when displayName is empty",
      () {
        final attr = _attr(
          claimPath: const ["address", "city"],
          displayName: const TranslatedValue.empty(),
        );
        expect(attr.effectiveDisplayName.translate("en"), "city");
      },
    );

    test("skips trailing int segments (array indices)", () {
      final attr = _attr(
        claimPath: const ["tags", 0],
        displayName: const TranslatedValue.empty(),
      );
      expect(attr.effectiveDisplayName.translate("en"), "tags");
    });

    test(
      "falls back to claimPath.join('.') when no string segment is present",
      () {
        final attr = _attr(
          claimPath: const [0, 1],
          displayName: const TranslatedValue.empty(),
        );
        expect(attr.effectiveDisplayName.translate("en"), "0.1");
      },
    );

    test("returns the empty displayName for empty claimPath", () {
      const empty = TranslatedValue.empty();
      final attr = _attr(claimPath: const [], displayName: empty);
      expect(attr.effectiveDisplayName.isEmpty, isTrue);
    });

    test("ignores non-string-non-int segments rather than rendering junk", () {
      // A double, bool, or null in a claim path should not produce
      // "true" / "0.5" labels — they're skipped just like ints.
      final attr = _attr(
        claimPath: const [3.14, true, "fieldName"],
        displayName: const TranslatedValue.empty(),
      );
      expect(attr.effectiveDisplayName.translate("en"), "fieldName");
    });
  });
}
