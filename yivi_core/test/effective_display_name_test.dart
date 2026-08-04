import "package:flutter_test/flutter_test.dart";

import "package:yivi_core/src/models/schemaless/schemaless_events.dart";

Attribute _attr({required List<dynamic> claimPath, String? displayName}) =>
    Attribute(claimPath: claimPath, displayName: displayName);

void main() {
  group("Attribute.effectiveDisplayName", () {
    test("returns displayName when set", () {
      final attr = _attr(claimPath: const ["dob"], displayName: "Birthdate");
      expect(attr.effectiveDisplayName, "Birthdate");
    });

    test(
      "falls back to last string segment of claimPath when displayName is empty",
      () {
        final attr = _attr(
          claimPath: const ["address", "city"],
          displayName: null,
        );
        expect(attr.effectiveDisplayName, "city");
      },
    );

    test("skips trailing int segments (array indices)", () {
      final attr = _attr(claimPath: const ["tags", 0], displayName: null);
      expect(attr.effectiveDisplayName, "tags");
    });

    test(
      "falls back to claimPath.join('.') when no string segment is present",
      () {
        final attr = _attr(claimPath: const [0, 1], displayName: null);
        expect(attr.effectiveDisplayName, "0.1");
      },
    );

    test("returns empty string for empty claimPath and empty displayName", () {
      final attr = _attr(claimPath: const [], displayName: null);
      expect(attr.effectiveDisplayName.isEmpty, isTrue);
    });

    test("ignores non-string-non-int segments rather than rendering junk", () {
      // A double, bool, or null in a claim path should not produce
      // "true" / "0.5" labels — they're skipped just like ints.
      final attr = _attr(
        claimPath: const [3.14, true, "fieldName"],
        displayName: null,
      );
      expect(attr.effectiveDisplayName, "fieldName");
    });
  });
}
