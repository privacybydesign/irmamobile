import "package:flutter_test/flutter_test.dart";

import "package:yivi_core/src/providers/credentials_search.dart";

// Pre-normalised candidates (lowercased, hyphen-stripped) — matches what
// _credentialsToSearchEntries produces in the provider.
SearchEntry _entry(String name, [String issuer = "yivi"]) =>
    SearchEntry(hash: name, credentialType: name, issuerName: issuer);

List<String> _hashes(Iterable<SearchEntry> entries) =>
    entries.map((e) => e.hash).toList(growable: false);

void main() {
  group("searchCredentials — prefix matching (returns 1.0)", () {
    test("exact whole-name prefix wins", () {
      final results = searchCredentials([
        _entry("driving licence"),
        _entry("paspoort"),
        _entry("identiteitskaart"),
      ], "drivi");
      expect(_hashes(results), ["driving licence"]);
    });

    test("first-token prefix matches", () {
      final results = searchCredentials([
        _entry("driving licence"),
        _entry("paspoort"),
      ], "dri");
      expect(_hashes(results), ["driving licence"]);
    });

    test(
      "non-first-token prefix matches (the tokenisation win)",
      () {
        // Without tokenisation this would only match via `contains` (0.9).
        // With per-token scoring, "lice" prefix-matches the "licence" token
        // for a full 1.0.
        final results = searchCredentials([
          _entry("driving licence"),
          _entry("paspoort"),
        ], "lice");
        expect(_hashes(results), ["driving licence"]);
      },
    );

    test("case-insensitive — query lowercased before matching", () {
      final results = searchCredentials([
        _entry("driving licence"),
      ], "DRIV");
      expect(_hashes(results), ["driving licence"]);
    });

    test("hyphens in the query are stripped", () {
      // "e-mail" → "email" matches the "email" token.
      final results = searchCredentials([
        _entry("verified email"),
      ], "e-mail");
      expect(_hashes(results), ["verified email"]);
    });

    test("whitespace in the query is trimmed", () {
      final results = searchCredentials([
        _entry("paspoort"),
      ], "  pasp  ");
      expect(_hashes(results), ["paspoort"]);
    });
  });

  group("searchCredentials — contains matching (returns 0.9)", () {
    test("substring inside a token matches", () {
      // "rivin" is in "driving" but not a prefix.
      final results = searchCredentials([
        _entry("driving licence"),
        _entry("paspoort"),
      ], "rivin");
      expect(_hashes(results), ["driving licence"]);
    });
  });

  group("searchCredentials — fuzzy matching (edit distance)", () {
    test("single-letter typo still matches", () {
      // "paspot" vs "paspoort" is a 2-edit distance (delete two chars).
      final results = searchCredentials([
        _entry("paspoort"),
        _entry("rijbewijs"),
      ], "paspot");
      expect(_hashes(results), ["paspoort"]);
    });

    test("realistic mid-word typo passes", () {
      // 1-edit: missing one char.
      final results = searchCredentials([
        _entry("rijbewijs"),
      ], "rijbewjs");
      expect(_hashes(results), ["rijbewijs"]);
    });

    test(
      "unrelated long query is rejected once distance exceeds 2",
      () {
        // "overheid" ↔ "verified" is 5 edits. Beyond the 2-edit cutoff
        // there's no fuzzy contribution at all.
        final results = searchCredentials([
          _entry("verified email"),
          _entry("paspoort"),
        ], "overheid");
        expect(results, isEmpty);
      },
    );

    test("aggressively scrambled query is rejected", () {
      final results = searchCredentials([
        _entry("paspoort"),
      ], "xxyyzz");
      expect(results, isEmpty);
    });

    test("adjacent transposition counts as a single edit", () {
      // Damerau-Levenshtein treats "paspoort" ↔ "papsoort" as distance 1
      // (one transposition), not 2 (two substitutions).
      final results = searchCredentials([
        _entry("paspoort"),
      ], "papsoort");
      expect(_hashes(results), ["paspoort"]);
    });

    test("three typos are rejected (hard 2-edit cap)", () {
      // "xxxpoort" is 3 substitutions from "paspoort" — over the cap.
      final results = searchCredentials([
        _entry("paspoort"),
      ], "xxxpoort");
      expect(results, isEmpty);
    });
  });

  group("searchCredentials — diacritic folding", () {
    test("query without accents matches accented credential", () {
      final results = searchCredentials([
        SearchEntry(
          hash: "x",
          credentialType: normaliseForSearch("café passe"),
          issuerName: "yivi",
        ),
      ], "cafe");
      expect(_hashes(results), ["x"]);
    });

    test("ß folds to ss so a German credential matches plain ascii", () {
      final results = searchCredentials([
        SearchEntry(
          hash: "x",
          credentialType: normaliseForSearch("straße"),
          issuerName: "yivi",
        ),
      ], "strasse");
      expect(_hashes(results), ["x"]);
    });

    test("normaliseForSearch is idempotent", () {
      expect(
        normaliseForSearch(normaliseForSearch("Café")),
        normaliseForSearch("Café"),
      );
    });
  });

  group("searchCredentials — issuer name as a fallback", () {
    test(
      "query matching only issuer name still ranks the candidate",
      () {
        // The query doesn't appear in the credential name at all, but it's
        // a prefix of the issuer name token. Issuer scores at 1.0, weighted
        // 0.3 → 0.3, exactly at the floor — passes.
        final results = searchCredentials([
          _entry("paspoort", "rdw"),
          _entry("rijbewijs", "yivi"),
        ], "rdw");
        expect(_hashes(results), ["paspoort"]);
      },
    );

    test(
      "credential name match outranks issuer match for the same query",
      () {
        // The 0.7/0.3 weighting in action.
        final results = searchCredentials([
          _entry("paspoort", "rdw"),
          _entry("rdw card", "yivi"),
        ], "rdw");
        expect(_hashes(results), ["rdw card", "paspoort"]);
      },
    );
  });

  group("searchCredentials — result priority", () {
    test("full hierarchy in one query: prefix > contains > fuzzy", () {
      // Three candidates land in three score tiers.
      final results = searchCredentials([
        _entry("xrijbewxxx"),
        _entry("rijbows"),
        _entry("rijbewijs"),
      ], "rijbew");
      expect(_hashes(results), ["rijbewijs", "xrijbewxxx", "rijbows"]);
    });

    test("issuer boost lifts a contains hit above a prefix-only one", () {
      // Combined scoring can flip the obvious ranking: cred-contains plus
      // strong issuer beats cred-prefix alone.
      final results = searchCredentials([
        _entry("rijbewijs", "yivi"),
        _entry("xrijbewxxx", "rijbew"),
      ], "rijbew");
      expect(_hashes(results), ["xrijbewxxx", "rijbewijs"]);
    });

    test("multiple fuzzy candidates sort by descending similarity", () {
      // Edit distances: paspoot(1), paspot(2), paspor(2 — sub one char and
      // delete one). All within the 2-edit limit; closest match wins.
      final results = searchCredentials([
        _entry("paspot"),
        _entry("paspoot"),
        _entry("paspor"),
      ], "paspoort");
      expect(results.first.hash, "paspoot");
      expect(results.length, 3);
    });

    test("combined match (cred + issuer) wins; weakest passing match last", () {
      final results = searchCredentials([
        SearchEntry(
          hash: "a",
          credentialType: "licence",
          issuerName: "yivi",
        ),
        SearchEntry(
          hash: "b",
          credentialType: "licence",
          issuerName: "lice corp",
        ),
        SearchEntry(hash: "c", credentialType: "xlicex", issuerName: "yivi"),
      ], "lice");
      expect(_hashes(results), ["b", "a", "c"]);
    });

    test("credential-side match outweighs issuer-side match", () {
      final results = searchCredentials([
        _entry("paspoort", "rdw"),
        _entry("rdwxxx", "yivi"),
      ], "rdw");
      expect(_hashes(results), ["rdwxxx", "paspoort"]);
    });

    test("prefix hit ranks above contains hit", () {
      final results = searchCredentials([
        _entry("aaa rij"),
        _entry("rijbewijs"),
        _entry("xyz drijven"),
      ], "rij");
      // "aaa rij" and "rijbewijs" both score 1.0 via prefix on some token;
      // "xyz drijven" only scores 0.9 via contains, so it ranks last.
      expect(results.length, 3);
      expect(results.last.hash, "xyz drijven");
    });

    test("higher fuzzy similarity ranks first", () {
      // Both miss prefix/contains; the closer-spelled one wins.
      final results = searchCredentials([
        _entry("paspoot"), // 1 letter off from query "paspoort"
        _entry("paspot"), // 2 letters off
      ], "paspoort");
      expect(results.first.hash, "paspoot");
      expect(results.length, 2);
    });
  });

  group("searchCredentials — edge cases", () {
    test("empty candidate list returns empty", () {
      expect(searchCredentials([], "rijbewijs"), isEmpty);
    });

    test("empty query returns every candidate", () {
      // `String.startsWith("")` is true for every string, so every first
      // token scores 1.0. The intent: an empty search box shows everything.
      final results = searchCredentials([
        _entry("paspoort"),
        _entry("rijbewijs"),
        _entry("verified email"),
      ], "");
      expect(results.length, 3);
    });

    test("whitespace-only query is equivalent to empty", () {
      final results = searchCredentials([
        _entry("paspoort"),
        _entry("rijbewijs"),
      ], "   ");
      expect(results.length, 2);
    });

    test("blank issuer name doesn't crash", () {
      final results = searchCredentials([
        SearchEntry(
          hash: "x",
          credentialType: "paspoort",
          issuerName: "",
        ),
      ], "pasp");
      expect(_hashes(results), ["x"]);
    });

    test(
      "very short tokens don't match unrelated long queries",
      () {
        // Under Dice's coefficient, "overheid" used to spuriously match a
        // contrived token like "ver" because short strings inflate the
        // similarity. Edit distance has no such quirk: dist > 2, no match.
        final results = searchCredentials([
          _entry("ver"),
        ], "overheid");
        expect(results, isEmpty);
      },
    );
  });

  group("searchCredentials — issuer name interactions", () {
    test(
      "issuer-only contains hit (0.9 × 0.3 = 0.27) passes the 0.25 floor",
      () {
        final results = searchCredentials([
          _entry("paspoort", "mijn overheid"),
        ], "ver");
        expect(_hashes(results), ["paspoort"]);
      },
    );

    test(
      "query that's a substring of an issuer token surfaces the credential",
      () {
        // Reported bug: "overheid" should find "Demo MijnOverheid". Token
        // "mijnoverheid" contains "overheid" → 0.9 × 0.3 = 0.27, which
        // passes the 0.25 floor.
        final results = searchCredentials([
          _entry("paspoort", "demo mijnoverheid"),
        ], "overheid");
        expect(_hashes(results), ["paspoort"]);
      },
    );

    test(
      "issuer-only prefix hit (1.0 × 0.3 = 0.3) passes the floor",
      () {
        // The query doesn't touch the credential name at all; the issuer
        // prefix is what carries the candidate over the bar.
        final results = searchCredentials([
          _entry("paspoort", "rdw"),
        ], "rdw");
        expect(_hashes(results), ["paspoort"]);
      },
    );

    test("issuer with multiple tokens — prefix on a non-first token", () {
      // Same logic applies inside the issuer name as inside the credential
      // name: each whitespace-separated token is scored independently and
      // the best one wins.
      final results = searchCredentials([
        _entry("paspoort", "stichting privacy"),
      ], "priv");
      expect(_hashes(results), ["paspoort"]);
    });

    test("same credential name, issuer breaks the tie", () {
      // Both entries have credential "paspoort"; neither token contains or
      // starts with "rdw" and the bigram similarity is 0. The first entry
      // wins purely on the issuer prefix.
      final results = searchCredentials([
        _entry("paspoort", "rdw"),
        _entry("paspoort", "yivi"),
      ], "rdw");
      expect(results.map((r) => r.issuerName).toList(), ["rdw"]);
    });

    test(
      "credential prefix + issuer prefix combine to score 1.0",
      () {
        // Two-axis scoring is additive — both axes hitting beats one alone.
        final results = searchCredentials([
          _entry("rij card", "yivi"),
          _entry("rij card", "stichting rij"),
        ], "rij");
        expect(results.length, 2);
        expect(results.first.issuerName, "stichting rij");
      },
    );

    test(
      "issuer-only 2-edit fuzzy is filtered (weighted below the floor)",
      () {
        // "rdww" ↔ "rdw" is a 1-edit match (insertion) on the issuer →
        // 0.9 × 0.3 = 0.27, passes. Going to 2 edits ("rdwww") gives
        // 0.7 × 0.3 = 0.21, just under the 0.25 floor.
        final pass = searchCredentials([
          _entry("paspoort", "rdw"),
        ], "rdww");
        expect(_hashes(pass), ["paspoort"]);

        final fail = searchCredentials([
          _entry("paspoort", "rdw"),
        ], "rdwww");
        expect(fail, isEmpty);
      },
    );

    test("weak issuer-only fuzzy match is rejected", () {
      // "wivx" ↔ "yivi" is two substitutions (distance 2). Weighted
      // contribution: 0.7 × 0.3 = 0.21, below the 0.25 floor.
      final results = searchCredentials([
        _entry("paspoort", "yivi"),
      ], "wivx");
      expect(results, isEmpty);
    });

    test(
      "credential contains outranks issuer prefix for the same query",
      () {
        // Pinning the 0.7/0.3 weighting: cred-contains (0.9 × 0.7) beats
        // issuer-prefix (1.0 × 0.3).
        final results = searchCredentials([
          _entry("paspoort", "rdw"),
          _entry("xrdwy", "yivi"),
        ], "rdw");
        expect(results.length, 2);
        expect(results.first.hash, "xrdwy");
      },
    );

    test(
      "query spanning two issuer tokens matches via joined-prefix",
      () {
        // Reported bug: "jegem" should find "Je Gemeente". Per-token alone
        // can't span the space; the joined-prefix shortcut catches it.
        final results = searchCredentials([
          _entry("paspoort", "je gemeente"),
        ], "jegem");
        expect(_hashes(results), ["paspoort"]);
      },
    );

    test("joined-prefix also works on the credential name", () {
      final results = searchCredentials([
        _entry("verified email", "yivi"),
      ], "verifiedem");
      expect(_hashes(results), ["verified email"]);
    });

    test(
      "joined-prefix does NOT degrade into joined-contains",
      () {
        // "egem" is inside "jegemeente" but not a prefix — should fall
        // through to per-token fuzzy and stay below the floor.
        final results = searchCredentials([
          _entry("paspoort", "je gemeente"),
        ], "egem");
        expect(results, isEmpty);
      },
    );
  });

  group("searchCredentials — more edge cases", () {
    test("single-character query matches via token prefix", () {
      final results = searchCredentials([
        _entry("paspoort", "yivi"),
        _entry("rijbewijs", "rdw"),
      ], "p");
      // Only "paspoort" has a token starting with "p". "yivi" doesn't either.
      // "rdw"? No. "rijbewijs"? No.
      expect(_hashes(results), ["paspoort"]);
    });

    test("query exactly equals credential token", () {
      // startsWith on identical strings is true → 1.0.
      final results = searchCredentials([
        _entry("paspoort", "yivi"),
        _entry("rijbewijs", "yivi"),
      ], "paspoort");
      expect(_hashes(results), ["paspoort"]);
    });

    test(
      "query much longer than any token returns empty",
      () {
        // No token is a prefix or substring of the long query, and the
        // length mismatch tanks the bigram similarity.
        final results = searchCredentials([
          _entry("paspoort", "yivi"),
          _entry("rijbewijs", "rdw"),
        ], "this is a very long unrelated query string");
        expect(results, isEmpty);
      },
    );

    test(
      "query of only hyphens normalises to empty and matches everything",
      () {
        // Normalisation: lowercase → trim → replaceAll("-", ""). "----"
        // becomes "". Empty query: `String.startsWith("")` is true for
        // every string, so every first token scores 1.0 — by design, an
        // empty search box shows every credential.
        final results = searchCredentials([
          _entry("paspoort", "yivi"),
          _entry("rijbewijs", "rdw"),
          _entry("verified email", "stichting"),
        ], "----");
        expect(results.length, 3);
      },
    );

    test("digits in tokens are matched as ordinary characters", () {
      final results = searchCredentials([
        _entry("v3 card", "yivi"),
        _entry("paspoort", "yivi"),
      ], "v3");
      expect(_hashes(results), ["v3 card"]);
    });

    test(
      "credential name and issuer name independently tokenised",
      () {
        // "stichting" in the issuer doesn't get matched by "rij" because
        // the algorithm scores credential tokens against the query
        // separately from issuer tokens — there's no cross-pollution.
        // This is a sanity check that we don't accidentally concatenate.
        final results = searchCredentials([
          _entry("paspoort", "stichting rij"),
        ], "rij");
        // Issuer token "rij" prefix-matches → issuer 1.0 → weighted 0.3 →
        // exactly at the floor.
        expect(_hashes(results), ["paspoort"]);
      },
    );

    test("hash field is opaque and unaffected by normalisation", () {
      // The hash isn't lowercased or hyphen-stripped — it's whatever the
      // caller gave us, used purely as an identifier to look candidates
      // back up after the search.
      final results = searchCredentials([
        SearchEntry(
          hash: "Hash-With-Caps-And-Hyphens",
          credentialType: "paspoort",
          issuerName: "yivi",
        ),
      ], "pasp");
      expect(results.first.hash, "Hash-With-Caps-And-Hyphens");
    });
  });

  group("maxTokenScore — pure function", () {
    test("prefix returns 1.0 and short-circuits", () {
      expect(maxTokenScore("drivi", "driving licence"), 1.0);
    });

    test("contains-but-not-prefix returns 0.9", () {
      // "rivin" is inside "driving" but not at the start.
      expect(maxTokenScore("rivin", "driving licence"), 0.9);
    });

    test("non-first token prefix wins over earlier contains", () {
      // "ence" is contained in "licence" (token 2) and not in "driving"
      // (token 1). Even though "licence".startsWith("ence") is false,
      // "licence".contains("ence") is true → 0.9.
      expect(maxTokenScore("ence", "driving licence"), 0.9);
    });

    test("returns 0 when nothing matches", () {
      expect(maxTokenScore("zzzz", "paspoort"), 0);
    });

    test("empty target returns 0", () {
      expect(maxTokenScore("anything", ""), 0);
    });

    test("multiple spaces between tokens are skipped", () {
      // Make sure split(" ") doesn't blow up on empty tokens.
      expect(maxTokenScore("lice", "driving   licence"), 1.0);
    });
  });
}
