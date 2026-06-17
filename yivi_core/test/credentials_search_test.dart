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

    test("query spanning two tokens does NOT match", () {
      // "ng lic" crosses a word boundary; no single token contains it.
      // Bigram similarity also stays low.
      final results = searchCredentials([
        _entry("driving licence"),
      ], "ng lic");
      expect(results, isEmpty);
    });
  });

  group("searchCredentials — fuzzy matching (Dice's coefficient)", () {
    test("single-letter typo still matches", () {
      // "paspot" vs "paspoort": Dice = 4·2 / (5+7) = 0.67 → credential
      // score 0.67·0.7 = 0.47, comfortably above the 0.3 floor.
      final results = searchCredentials([
        _entry("paspoort"),
        _entry("rijbewijs"),
      ], "paspot");
      expect(_hashes(results), ["paspoort"]);
    });

    test("realistic mid-word typo passes", () {
      // "rijbewjs" missing one char from "rijbewijs". Dice ≈ 0.86 → passes.
      final results = searchCredentials([
        _entry("rijbewijs"),
      ], "rijbewjs");
      expect(_hashes(results), ["rijbewijs"]);
    });

    test(
      "unrelated query that only shares common bigrams falls below floor",
      () {
        // The regression case: "overheid" and "verified" share only "ve"
        // and "er" (very common latin bigrams), giving 4/14 ≈ 0.29. Below
        // the 0.3 floor even on a one-token credential, and "verified email"
        // adds the unrelated "email" token diluting it further.
        final results = searchCredentials([
          _entry("verified email"),
          _entry("paspoort"),
        ], "overheid");
        expect(results, isEmpty);
      },
    );

    test("aggressively scrambled query is rejected", () {
      // "xxyyzz" vs "paspoort" → zero shared bigrams.
      final results = searchCredentials([
        _entry("paspoort"),
      ], "xxyyzz");
      expect(results, isEmpty);
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
      // None hit prefix or contains — all fall through to fuzzy.
      final results = searchCredentials([
        _entry("paspoortennn"),
        _entry("paspoort"),
        _entry("paspoorten"),
      ], "paspot");
      expect(_hashes(results), ["paspoort", "paspoorten", "paspoortennn"]);
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
      "tokenisation degrades for very short tokens",
      () {
        // A pitfall worth documenting rather than papering over: Dice's
        // coefficient on bigrams favours short strings, because shared
        // bigrams loom larger in the denominator. Per-token max therefore
        // gives a HIGHER score for a contrived name like "ver" (2 bigrams,
        // both shared with "overheid") than for a realistic name like
        // "verified" (7 bigrams, same 2 shared). In practice credential
        // names are full words, so this edge case doesn't bite — but the
        // test pins the behaviour so a future tweak to the floor doesn't
        // surprise us.
        // "ver" vs "overheid": Dice = 2·2/(2+7) = 0.444 → 0.444·0.7 = 0.311,
        // just over the 0.3 floor.
        final results = searchCredentials([
          _entry("ver"),
        ], "overheid");
        expect(_hashes(results), ["ver"]);
      },
    );
  });

  group("searchCredentials — issuer name interactions", () {
    test(
      "issuer-only contains hit (0.9 × 0.3 = 0.27) is below the floor",
      () {
        // "mijn overheid" issuer: "overheid".contains("ver") is true
        // (positions 1–3), but neither token starts with "ver". Issuer
        // score 0.9, weighted to 0.27 — under the 0.3 floor. Picked "ver"
        // specifically because its bigrams ("ve","er") share nothing with
        // "paspoort" (so credential side contributes a clean 0), otherwise
        // small bigram leaks would inflate the combined score over the floor.
        final results = searchCredentials([
          _entry("paspoort", "mijn overheid"),
        ], "ver");
        expect(results, isEmpty);
      },
    );

    test(
      "issuer-only prefix hit (1.0 × 0.3 = 0.3) lands exactly at the floor",
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
      "borderline credential fuzzy + borderline issuer fuzzy can combine over the floor",
      () {
        // Pinning a real edge of the algorithm: a credential token's
        // sub-floor fuzzy score (0.286 for "overheid" ↔ "verified", weighted
        // to 0.2) plus an issuer token's also-sub-floor fuzzy score (0.375
        // for "overheid" ↔ "government", weighted to ≈0.11) sums to ≈0.31
        // — just over 0.3. If we want this case filtered, the floor needs
        // to rise further, but at the cost of typo tolerance elsewhere.
        final results = searchCredentials([
          _entry("verified email", "government"),
        ], "overheid");
        expect(_hashes(results), ["verified email"]);
      },
    );

    test("weak issuer-only fuzzy match is rejected", () {
      // "yvi" ↔ "yivi" Dice = 2 / (2+3) = 0.40 — would pass on its own
      // (above the 0.3 floor) only if it weren't downweighted to 0.3 of the
      // total. Weighted contribution: 0.4 × 0.3 = 0.12. Credential side
      // contributes 0. Combined: 0.12, filtered.
      final results = searchCredentials([
        _entry("paspoort", "yivi"),
      ], "yvi");
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
