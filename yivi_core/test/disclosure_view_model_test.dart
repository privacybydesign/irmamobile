import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/models/schemaless/credential_store.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/schemaless/session_state.dart";
import "package:yivi_core/src/screens/session/models/disclosure_view_model.dart";

// The scenarios of the "Yivi Disclosure Flows" canvas, as session states.

TrustedParty _party(String name) =>
    TrustedParty(id: name, name: name, url: null, parent: null, verified: true);

const _future = 4102444800; // 2100-01-01
const _past = 946684800; // 2000-01-01

SelectableCredentialInstance _instance(
  String id, {
  String hash = "h",
  bool revoked = false,
  int? batch,
  int? expiry = _future,
  CredentialFormat format = CredentialFormat.idemix,
  String issuer = "Gemeente",
  String? issueUrl,
}) => SelectableCredentialInstance(
  credentialId: id,
  hash: hash,
  name: id,
  issuer: _party(issuer),
  format: format,
  attributes: const [],
  revoked: revoked,
  revocationSupported: revoked,
  batchInstanceCountRemaining: batch,
  expiryDate: expiry,
  issueUrl: issueUrl,
);

CredentialDescriptor _descriptor(
  String id, {
  String? url = "https://www.issuer.example/get",
  List<Attribute> attributes = const [],
  String issuer = "Issuer",
}) => CredentialDescriptor(
  credentialId: id,
  name: id,
  issuer: _party(issuer),
  category: null,
  attributes: attributes,
  issueURL: url,
);

DisclosureBundle _bundle(List<SelectableCredentialInstance> cards) =>
    DisclosureBundle(credentials: cards);

DisclosurePickOne _pickOne({
  List<DisclosureBundle> owned = const [],
  List<CredentialDescriptor> obtainable = const [],
  bool optional = false,
}) => DisclosurePickOne(
  optional: optional,
  ownedOptions: owned,
  obtainableOptions: obtainable,
);

SessionState _session(
  List<DisclosurePickOne> pickOnes, {
  SessionType type = SessionType.disclosure,
  List<Credential>? offered,
}) => SessionState(
  id: 1,
  protocol: "irma",
  type: type,
  status: SessionStatus.requestPermission,
  requestor: _party("Webshop Noord"),
  disclosurePlan: DisclosurePlan(disclosureChoicesOverview: pickOnes),
  offeredCredentials: offered,
);

Credential _offered(String id, List<Attribute> attributes) => Credential(
  credentialId: id,
  hash: "offered-$id",
  name: id,
  issuer: _party("Issuer"),
  credentialInstanceIds: {CredentialFormat.idemix: "offered-$id"},
  batchInstanceCountsRemaining: const {},
  attributes: attributes,
  revoked: false,
  revocationSupported: false,
  issueUrl: null,
);

Attribute _string(String path, String value, {String? requested}) => Attribute(
  claimPath: [path],
  displayName: path,
  value: AttributeValue(type: AttributeType.string, string: value),
  requestedValue: requested == null
      ? null
      : AttributeValue(type: AttributeType.string, string: requested),
);

void main() {
  group("card problems", () {
    test("a valid card has none", () {
      expect(problemOf(_instance("email")), isNull);
    });

    test("revoked wins over used up and expired", () {
      expect(
        problemOf(_instance("a", revoked: true, batch: 0, expiry: _past)),
        CardProblem.revoked,
      );
    });

    test("no batch copies left is used up", () {
      expect(
        problemOf(_instance("pid", batch: 0, format: CredentialFormat.msoMdoc)),
        CardProblem.usedUp,
      );
    });

    test("past its expiry date is expired", () {
      expect(problemOf(_instance("a", expiry: _past)), CardProblem.expired);
    });

    test("one copy left is the last use, not a problem", () {
      final card = _instance("age", batch: 1, format: CredentialFormat.sdjwtvc);
      expect(problemOf(card), isNull);
      expect(isLastUse(card), isTrue);
      expect(isLastUse(_instance("age", batch: 2)), isFalse);
    });
  });

  group("hosts and what can be added", () {
    test("the host drops www.", () {
      expect(
        hostOf("https://www.privacybydesign.foundation/x"),
        "privacybydesign.foundation",
      );
      expect(hostOf("https://idin.yivi.app"), "idin.yivi.app");
    });

    test("no URL, no host, cannot be added", () {
      expect(hostOf(null), isNull);
      expect(hostOf(""), isNull);
      expect(canBeAdded(_descriptor("voting", url: null)), isFalse);
    });

    test("only types with an issue URL are offered to add", () {
      final pickOne = _pickOne(
        obtainable: [_descriptor("email"), _descriptor("pid", url: null)],
      );
      expect(addableOptions(pickOne).map((d) => d.credentialId), ["email"]);
    });
  });

  group("selection", () {
    final twoEmails = _pickOne(
      owned: [
        _bundle([_instance("email", hash: "new")]),
        _bundle([_instance("email", hash: "old")]),
      ],
      obtainable: [_descriptor("email")],
    );

    test("required data starts on irmago's first option", () {
      expect(defaultSelection(twoEmails), 0);
    });

    test("optional data starts left out", () {
      expect(
        defaultSelection(
          _pickOne(owned: twoEmails.ownedOptions!, optional: true),
        ),
        -1,
      );
    });

    test("a stale selection falls back to the default", () {
      expect(selectionOf(twoEmails, 1), 1);
      expect(selectionOf(twoEmails, 5), 0);
      expect(selectionOf(twoEmails, -1), 0);
    });

    test("Change shows when there is more than one thing to choose", () {
      expect(canChange(twoEmails), isTrue);
      expect(
        canChange(
          _pickOne(
            owned: [
              _bundle([_instance("email")]),
            ],
          ),
        ),
        isFalse,
      );
      expect(
        canChange(
          _pickOne(
            owned: [
              _bundle([_instance("email")]),
            ],
            obtainable: [_descriptor("mobile")],
          ),
        ),
        isTrue,
      );
    });
  });

  group("share button", () {
    test("Share when everything is fine", () {
      final state = _session([
        _pickOne(
          owned: [
            _bundle([_instance("email")]),
          ],
        ),
      ]);
      final button = shareButton(state, const {});
      expect(button.label, ShareLabel.share);
      expect(button.enabled, isTrue);
    });

    test("signing and receiving get their own label", () {
      final pickOnes = [
        _pickOne(
          owned: [
            _bundle([_instance("email")]),
          ],
        ),
      ];
      expect(
        shareButton(
          _session(pickOnes, type: SessionType.signature),
          const {},
        ).label,
        ShareLabel.signAndShare,
      );
      expect(
        shareButton(
          _session(pickOnes, offered: [_offered("student", const [])]),
          const {},
        ).label,
        ShareLabel.shareAndAdd,
      );
    });

    test("nothing required and nothing added: share without data", () {
      final state = _session([
        _pickOne(obtainable: [_descriptor("email")], optional: true),
      ]);
      expect(shareButton(state, const {}).label, ShareLabel.shareWithoutData);
    });

    test("a revoked card that can be renewed blocks sharing", () {
      final state = _session([
        _pickOne(
          owned: [
            _bundle([_instance("address", revoked: true)]),
          ],
          obtainable: [_descriptor("address")],
        ),
      ]);
      final button = shareButton(state, const {});
      expect(button.enabled, isFalse);
      expect(button.blockedBy, CardProblem.revoked);
      expect(button.label, ShareLabel.share);
      expect(
        fixFor(
          state.disclosurePlan!.disclosureChoicesOverview!.first,
          state
              .disclosurePlan!
              .disclosureChoicesOverview!
              .first
              .ownedOptions!
              .first,
        )?.credentialId,
        "address",
      );
    });

    test("a revoked card without other options is renewed at its issuer", () {
      final pickOne = _pickOne(
        owned: [
          _bundle([
            _instance(
              "root",
              revoked: true,
              issueUrl: "https://portal.example/root",
            ),
          ]),
        ],
      );
      final fix = fixFor(pickOne, pickOne.ownedOptions!.first);
      expect(fix?.credentialId, "root");
      expect(fix?.issueURL, "https://portal.example/root");
      final button = shareButton(_session([pickOne]), const {});
      expect(button.label, ShareLabel.share);
      expect(button.enabled, isFalse);
      expect(button.blockedBy, CardProblem.revoked);
    });

    test("a used-up card that cannot be renewed in Yivi closes", () {
      final state = _session([
        _pickOne(
          owned: [
            _bundle([
              _instance(
                "pid",
                batch: 0,
                format: CredentialFormat.msoMdoc,
                issuer: "EUDI PID Issuer",
              ),
            ]),
          ],
        ),
      ]);
      final button = shareButton(state, const {});
      expect(button.label, ShareLabel.close);
      expect(button.cannotRenewFrom, "EUDI PID Issuer");
    });

    test("a problem on optional data that is left out does not block", () {
      final state = _session([
        _pickOne(
          owned: [
            _bundle([_instance("email")]),
          ],
        ),
        _pickOne(
          owned: [
            _bundle([_instance("mobile", revoked: true)]),
          ],
          optional: true,
        ),
      ]);
      expect(shareButton(state, const {}).enabled, isTrue);
    });

    test("picking another owned card clears the block", () {
      final state = _session([
        _pickOne(
          owned: [
            _bundle([_instance("email", hash: "a", revoked: true)]),
            _bundle([_instance("email", hash: "b")]),
          ],
        ),
      ]);
      expect(shareButton(state, const {}).enabled, isFalse);
      expect(shareButton(state, const {0: 1}).enabled, isTrue);
    });
  });

  group("empty spots", () {
    test("a required item with no card in the app is an empty spot", () {
      expect(isEmptySpot(_pickOne(obtainable: [_descriptor("email")])), isTrue);
      expect(
        isEmptySpot(
          _pickOne(
            owned: [
              _bundle([_instance("email")]),
            ],
          ),
        ),
        isFalse,
      );
      // Optional data that is not in the app is an "Add" row instead.
      expect(
        isEmptySpot(
          _pickOne(obtainable: [_descriptor("email")], optional: true),
        ),
        isFalse,
      );
    });

    test("Share waits for it: Add {name} first", () {
      final spot = _pickOne(
        obtainable: [_descriptor("email"), _descriptor("mobile")],
      );
      final state = _session([
        _pickOne(
          owned: [
            _bundle([_instance("name")]),
          ],
        ),
        spot,
      ]);
      final button = shareButton(state, const {});
      expect(button.enabled, isFalse);
      expect(button.label, ShareLabel.share);
      expect(button.missing, spot);
      expect(spotName(spot, " or "), "email or mobile");
    });

    test("nothing to add it from in Yivi: Close, and where to get it", () {
      final spot = _pickOne(
        obtainable: [
          _descriptor("voting", url: null, issuer: "Demo Voting Card Issuer"),
        ],
      );
      final button = shareButton(_session([spot]), const {});
      expect(button.label, ShareLabel.close);
      expect(button.enabled, isTrue);
      expect(button.cannotAdd, spot);
    });

    test(
      "a card added with the wrong value: what was added, what is needed",
      () {
        final spot = _pickOne(
          obtainable: [
            _descriptor(
              "ideal",
              attributes: [_string("bic", "", requested: "RABONL2U")],
            ),
          ],
        );
        final plan = IssueDuringDisclosure(
          steps: const [],
          wrongCredentialIssued: _offered("ideal", [
            _string("bic", "INGBNL2A"),
          ]),
        );
        final mismatch = spotMismatch(spot, plan);
        expect(mismatch?.offered?.string, "INGBNL2A");
        expect(mismatch?.required.string, "RABONL2U");
        // A wrong card of another type is not this spot's.
        expect(
          spotMismatch(_pickOne(obtainable: [_descriptor("email")]), plan),
          isNull,
        );
      },
    );

    test("types only accepted together are one set", () {
      final spot = _pickOne(
        obtainable: [_descriptor("root"), _descriptor("name")],
      );
      IssueDuringDisclosure steps(List<List<String>> options) =>
          IssueDuringDisclosure(
            steps: [
              IssuanceStep(
                options: [
                  for (final o in options)
                    IssuanceBundle(
                      credentials: [for (final id in o) _descriptor(id)],
                    ),
                ],
              ),
            ],
          );
      expect(
        spotTogether(
          spot,
          steps([
            ["root", "name"],
          ]),
        ),
        isTrue,
      );
      expect(spotName(spot, " or ", together: true), "root + name");
      // Either one is enough: a choice, not a set.
      expect(
        spotTogether(
          spot,
          steps([
            ["root"],
            ["name"],
          ]),
        ),
        isFalse,
      );
      expect(spotTogether(spot, null), isFalse);
    });

    test("the values the request needs", () {
      final spot = _pickOne(
        obtainable: [
          _descriptor(
            "ideal",
            attributes: [
              _string("bic", "", requested: "RABONL2U"),
              _string("iban", ""),
            ],
          ),
        ],
      );
      final values = spotRequiredValues(spot);
      expect(values, hasLength(1));
      expect(values.single.$1, "bic");
      expect(values.single.$2.string, "RABONL2U");
    });

    test("a card added during the request is marked", () {
      final pickOne = _pickOne(
        owned: [
          _bundle([_instance("email")]),
        ],
      );
      final plan = IssueDuringDisclosure(
        steps: const [],
        issuedCredentialIds: const {"email": <String, dynamic>{}},
      );
      expect(
        addedDuringRequest(pickOne, pickOne.ownedOptions![0], plan),
        isTrue,
      );
      expect(
        addedDuringRequest(pickOne, pickOne.ownedOptions![0], null),
        isFalse,
      );
    });
  });

  group("issuance inside a request", () {
    final steps = [
      IssuanceStep(
        options: [
          IssuanceBundle(credentials: [_descriptor("idin")]),
        ],
      ),
      IssuanceStep(
        options: [
          IssuanceBundle(
            credentials: [
              _descriptor(
                "ideal",
                attributes: [_string("bic", "", requested: "RABONL2U")],
              ),
            ],
          ),
        ],
      ),
    ];

    test("an offered value that differs from the requested one", () {
      final mismatches = issuanceMismatches([
        _offered("ideal", [_string("bic", "INGBNL2A")]),
      ], steps);
      expect(mismatches, hasLength(1));
      expect(mismatches.single.attributeName, "bic");
      expect(mismatches.single.offered?.string, "INGBNL2A");
      expect(mismatches.single.required.string, "RABONL2U");
    });

    test("a matching value is no mismatch", () {
      expect(
        issuanceMismatches([
          _offered("ideal", [_string("bic", "RABONL2U")]),
        ], steps),
        isEmpty,
      );
    });

    test("the step an offered card belongs to", () {
      expect(stepNumberFor([_offered("ideal", const [])], steps), 2);
      expect(stepNumberFor([_offered("other", const [])], steps), isNull);
      expect(
        stepNumberFor([_offered("idin", const [])], steps.take(1).toList()),
        isNull,
      );
    });
  });

  test("names inside a sentence keep abbreviations", () {
    expect(inSentence("Email address"), "email address");
    expect(inSentence("ID card"), "ID card");
    expect(inSentence("iDIN"), "iDIN");
    expect(inSentence("BSN"), "BSN");
    expect(inSentence("Email-Adresse", language: "de"), "Email-Adresse");
  });

  group("what optional data asks for", () {
    Attribute field(String name, {bool requested = true}) => Attribute(
      claimPath: [name],
      displayName: name,
      requestedValue: requested
          ? AttributeValue(type: AttributeType.string)
          : null,
    );
    SelectableCredentialInstance card(String id, List<String> fields) =>
        SelectableCredentialInstance(
          credentialId: id,
          hash: "h-$id",
          name: id,
          issuer: _party("Gemeente"),
          format: CredentialFormat.idemix,
          attributes: [for (final f in fields) field(f)],
          revoked: false,
          revocationSupported: false,
        );

    test("the fields of the first card in the app", () {
      expect(
        optionalWhat(
          _pickOne(
            optional: true,
            owned: [
              _bundle([
                card("Personal data", ["Date of birth"]),
              ]),
              _bundle([
                card("Passport", ["Born", "Name"]),
              ]),
            ],
          ),
        ),
        const OptionalWhat(byCard: false, names: ["Date of birth"]),
      );
    });

    test("nothing in the app: the requested fields of the first to add", () {
      expect(
        optionalWhat(
          _pickOne(
            optional: true,
            obtainable: [
              _descriptor(
                "Mobile number",
                attributes: [
                  field("Mobile number"),
                  field("Country", requested: false),
                ],
              ),
            ],
          ),
        ),
        const OptionalWhat(byCard: false, names: ["Mobile number"]),
      );
    });

    test("a set: the fields of both cards, once each", () {
      expect(
        optionalWhat(
          _pickOne(
            optional: true,
            owned: [
              _bundle([
                card("Personal data", ["Name"]),
                card("Address", ["Street", "Name"]),
              ]),
            ],
          ),
        ),
        const OptionalWhat(byCard: false, names: ["Name", "Street"]),
      );
    });

    test("more than three fields: named by the cards", () {
      expect(
        optionalWhat(
          _pickOne(
            optional: true,
            owned: [
              _bundle([
                card("Personal data", ["First names", "Surname"]),
                card("Address", ["Street", "Postcode"]),
              ]),
            ],
          ),
        ),
        const OptionalWhat(byCard: true, names: ["Personal data", "Address"]),
      );
    });

    test("nothing in the app, a set to complete: the fields of its cards", () {
      expect(
        optionalWhat(
          DisclosurePickOne(
            optional: true,
            ownedOptions: const [],
            obtainableBundles: [
              ObtainableBundle(
                owned: [
                  card("Address", ["Street"]),
                ],
                missing: [
                  _descriptor("Passport", attributes: [field("Name")]),
                ],
              ),
            ],
          ),
        ),
        const OptionalWhat(byCard: false, names: ["Name", "Street"]),
      );
    });

    test("what can be completed: the sets irmago sends, or one type each", () {
      final passport = _descriptor("Passport");
      final address = card("Address", ["Street"]);
      final noUrl = _descriptor("mdoc", url: null);
      final sets = addableBundles(
        DisclosurePickOne(
          optional: true,
          obtainableOptions: [passport, noUrl],
          obtainableBundles: [
            ObtainableBundle(owned: [address], missing: [passport]),
            ObtainableBundle(owned: const [], missing: [noUrl]),
          ],
        ),
      );
      expect(sets, hasLength(1));
      expect(sets.single.owned.single.credentialId, "Address");

      final types = addableBundles(
        _pickOne(optional: true, obtainable: [passport, noUrl]),
      );
      expect([for (final b in types) b.missing.single], [passport]);
      expect(types.single.owned, isEmpty);
    });

    test("a list in a sentence", () {
      expect(andList(["a"], " and "), "a");
      expect(andList(["a", "b", "c"], " and "), "a, b and c");
    });
  });

  group("the share screen's words", () {
    test("a list: commas, and or before the last", () {
      expect(orList(["passport"], " or "), "passport");
      expect(orList(["email", "mobile"], " or "), "email or mobile");
      expect(
        orList(["passport", "ID card", "licence", "personal data"], " or "),
        "passport, ID card, licence or personal data",
      );
    });

    test("a spot's name writes the types after the first in the list", () {
      final spot = _pickOne(
        obtainable: [_descriptor("Passport"), _descriptor("ID card")],
      );
      expect(
        spotName(spot, " or ", inList: (n) => n.toLowerCase()),
        "Passport or id card",
      );
    });

    test("you can also choose: your other or your, never a", () {
      // Two email addresses and one mobile number in the app, the first
      // email address selected; another email address and a BSN can be
      // added.
      final pickOne = _pickOne(
        owned: [
          _bundle([_instance("email", hash: "e1")]),
          _bundle([_instance("email", hash: "e2")]),
          _bundle([_instance("mobile", hash: "m1")]),
        ],
        obtainable: [_descriptor("email"), _descriptor("bsn")],
      );
      expect(alsoChoose(pickOne, 0), [
        (AlsoKind.other, "email"),
        (AlsoKind.your, "mobile"),
        (AlsoKind.your, "bsn"),
      ]);
      // The mobile number selected: the two email addresses (and the one to
      // add) are named once.
      expect(alsoChoose(pickOne, 2), [
        (AlsoKind.your, "email"),
        (AlsoKind.your, "bsn"),
      ]);
    });

    test("the footnote only when the button shares something", () {
      final owned = _pickOne(
        owned: [
          _bundle([_instance("email")]),
        ],
      );
      final missing = _pickOne(obtainable: [_descriptor("mobile")]);
      final optional = _pickOne(
        optional: true,
        owned: [
          _bundle([_instance("name")]),
        ],
      );

      final ok = _session([owned]);
      expect(showFootnote(shareButton(ok, const {0: 0}), const {0: 0}), isTrue);

      // A card still to be added: not yet.
      final waiting = _session([owned, missing]);
      const sel = {0: 0, 1: -1};
      expect(showFootnote(shareButton(waiting, sel), sel), isFalse);

      // Nothing shared at all.
      final nothing = _session([optional]);
      const none = {0: -1};
      expect(showFootnote(shareButton(nothing, none), none), isFalse);
    });

    test("the card that blocks sharing is named", () {
      final address = _bundle([_instance("address", revoked: true)]);
      final button = shareButton(
        _session([
          _pickOne(owned: [address], obtainable: [_descriptor("address")]),
        ]),
        const {0: 0},
      );
      expect(button.enabled, isFalse);
      expect(button.blockedCard, address);
    });
  });
}
