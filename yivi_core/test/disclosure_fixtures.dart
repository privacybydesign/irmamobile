// The design prototype's example requests (docs/design/disclosure-add-first-canvas,
// `KZ_SC` in Deel.dc.html) as disclosure plans, for the rules' tests.
//
// The prototype's model maps onto irmago's as follows: a group is a choice, an
// option a list of slots, a card the app holds a usable candidate. A card with
// a problem ("verlopen", "ingetrokken") is a candidate irmago marks unusable;
// one with another value than is asked ("telt") is no candidate at all, but a
// card in the wallet. A kind that allows another card ("more") offers a
// descriptor with an issue URL; one Yivi cannot add ("cant") offers one
// without. The same query in two options (`ref`) or two sets (`link`) is the
// same slot id.

import "package:yivi_core/src/models/credential.dart";
import "package:yivi_core/src/models/credential_store.dart";
import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/models/protocol.dart";
import "package:yivi_core/src/models/session_state.dart";

/// A card kind of the prototype (`KZ_TYPE`).
class Kind {
  final String id;
  final String name;
  final String issuer;

  /// Another card of the kind can be added ("Ander …").
  final bool more;

  const Kind(this.id, this.name, this.issuer, {this.more = false});
}

const email = Kind("email", "E-mailadres", "Yivi", more: true);
const phone = Kind("phone", "Mobiel telefoonnummer", "Yivi", more: true);
const passport = Kind("passport", "Paspoort", "Yivi", more: true);
const idcard = Kind("idcard", "Identiteitskaart", "Yivi", more: true);
const driving = Kind("driving", "Rijbewijs", "Yivi", more: true);
const personal = Kind("personal", "Persoonsgegevens", "Demo MijnOverheid.nl");
const address = Kind("address", "Adres", "Gemeente Rijnstad");
const exam = Kind("exam", "Toetsinschrijving", "Hogeschool Rijnstad");
const diploma = Kind("diploma", "Diploma", "DUO", more: true);
const iban = Kind("iban", "Bankrekening", "iDEAL", more: true);
const pid = Kind("pid", "EU-identiteit", "issuer.eudiw.dev", more: true);
const study = Kind("study", "Studiegegevens", "Universiteit Rijnstad");

TrustedParty party(String name) =>
    TrustedParty(id: name, name: name, url: null, parent: null, verified: true);

/// A value row: a name and a string, or a nested value as the prototype
/// writes it (a list of rows for an object, a list of strings or of row lists
/// for a list).
typedef Row = (String, Object);

AttributeValue text(String v) =>
    AttributeValue(type: AttributeType.string, string: v);

/// The attributes for [rows], nested as irmago sends them: an object or list
/// is a header (no value) followed by its fields at longer claim paths.
List<Attribute> attrs(
  List<Row> rows, {
  List<dynamic> under = const [],
  Set<String> keep = const {},
  Map<String, List<String>> asked = const {},
}) {
  final out = <Attribute>[];
  for (final (name, v) in rows) {
    final path = [...under, name];
    if (v is String) {
      final allowed = asked[name];
      out.add(
        Attribute(
          claimPath: path,
          displayName: name,
          value: text(v),
          requestedValue: allowed == null ? null : text(allowed.first),
          requestedValues: [
            for (final a in allowed ?? const <String>[]) text(a),
          ],
          intentToRetain: keep.contains(name) ? true : null,
        ),
      );
    } else if (v is List<Row>) {
      out.add(Attribute(claimPath: path, displayName: name));
      out.addAll(attrs(v, under: path));
    } else if (v is List<String>) {
      out.add(Attribute(claimPath: path, displayName: name));
      for (final (i, item) in v.indexed) {
        out.add(
          Attribute(
            claimPath: [...path, i],
            displayName: null,
            value: text(item),
          ),
        );
      }
    } else if (v is List<List<Row>>) {
      out.add(Attribute(claimPath: path, displayName: name));
      for (final (i, item) in v.indexed) {
        out.addAll(attrs(item, under: [...path, i]));
      }
    }
  }
  return out;
}

/// A descriptor of [kind] asking [rows]' names, with [asked] allowed values;
/// [url] false: Yivi cannot add it.
CredentialDescriptor descriptor(
  Kind kind, {
  List<Row> rows = const [],
  Map<String, List<String>> asked = const {},
  bool url = true,
  bool singleton = false,
}) => CredentialDescriptor(
  credentialId: kind.id,
  name: kind.name,
  issuer: party(kind.issuer),
  category: null,
  attributes: [
    for (final (name, _) in rows)
      Attribute(
        claimPath: [name],
        displayName: name,
        requestedValue: asked[name] == null ? null : text(asked[name]!.first),
        requestedValues: [
          for (final a in asked[name] ?? const <String>[]) text(a),
        ],
      ),
  ],
  issueURL: url ? "https://${kind.id}.example/add" : null,
  isSingleton: singleton || !kind.more,
);

int _hashes = 0;

/// A card of [kind] in the app with [rows]; [reason] makes it unusable.
SelectableCredentialInstance card(
  Kind kind,
  List<Row> rows, {
  UnusableReason? reason,
  Set<String> keep = const {},
  Map<String, List<String>> asked = const {},
  String? hash,
}) => SelectableCredentialInstance(
  credentialId: kind.id,
  hash: hash ?? "${kind.id}-${++_hashes}",
  name: kind.name,
  issuer: party(kind.issuer),
  format: CredentialFormat.idemix,
  attributes: attrs(rows, keep: keep, asked: asked),
  revoked: reason == UnusableReason.revoked,
  revocationSupported: false,
  isSingleton: !kind.more,
  usable: reason == null,
  unusableReason: reason,
);

/// A slot of [kind]: the cards in the app ([cards]) and, when Yivi can add
/// one ([add]: null follows the kind; for a slot without cards, always), the
/// descriptor. [cant]: Yivi cannot add it.
DisclosureSlot slot(
  Kind kind,
  List<SelectableCredentialInstance> cards, {
  String? id,
  bool? add,
  bool cant = false,
  bool multiple = false,
  List<Row> asks = const [],
  Map<String, List<String>> asked = const {},
}) {
  final usable = cards.any((c) => c.usable);
  final offered = cant ? true : add ?? (!usable || kind.more);
  return DisclosureSlot(
    id: id ?? kind.id,
    multiple: multiple,
    candidates: cards,
    obtainable: offered
        ? [descriptor(kind, rows: asks, asked: asked, url: !cant)]
        : const [],
  );
}

DisclosureOption option(List<DisclosureSlot> slots) =>
    DisclosureOption(slots: slots);

DisclosureChoice choice(List<DisclosureOption> options, {bool opt = false}) =>
    DisclosureChoice(optional: opt, options: options);

DisclosureChoice one(DisclosureSlot s, {bool opt = false}) => choice([
  option([s]),
], opt: opt);

DisclosurePlan plan(List<DisclosureChoice> choices) =>
    DisclosurePlan(choices: choices);

/// A card in the wallet of [kind] with [rows] (for a value the request does
/// not accept).
Credential walletCard(Kind kind, List<Row> rows, {String? hash}) => Credential(
  credentialId: kind.id,
  hash: hash ?? "${kind.id}-w${++_hashes}",
  name: kind.name,
  issuer: party(kind.issuer),
  credentialInstanceIds: const {},
  batchInstanceCountsRemaining: const {},
  attributes: attrs(rows),
  revoked: false,
  revocationSupported: false,
  issueUrl: null,
);

// --- Values -------------------------------------------------------------------

const List<Row> id3 = [
  ("Voornamen", "Sanne"),
  ("Achternaam", "de Vries"),
  ("Geboortedatum", "12 maart 1991"),
];
const List<Row> doc = [...id3, ("Documentnummer", "NX4R7K2P9")];
const List<Row> doc2 = [...id3, ("Documentnummer", "PK7T2M4X1")];
const List<Row> over18 = [("Ouder dan 18", "Ja")];
const List<Row> mail1 = [("E-mailadres", "sanne@example.nl")];
const List<Row> mail2 = [("E-mailadres", "s.devries@werk.example")];
const List<Row> mail3 = [("E-mailadres", "sanne@studie.example")];
const List<Row> tel = [("Mobiel telefoonnummer", "06 12345678")];
const List<Row> adr = [
  ("Straat", "Lindelaan 12"),
  ("Postcode", "1234 AB"),
  ("Woonplaats", "Rijnstad"),
];

// --- The scenarios ---------------------------------------------------------------

DisclosurePlan eenvoudig() => plan([
  one(slot(email, [card(email, mail1, hash: "e-1")])),
]);

DisclosurePlan keuze() => plan([
  choice([
    option([
      slot(passport, [
        card(passport, over18, hash: "pp-1"),
        card(passport, over18, hash: "pp-2"),
      ]),
    ]),
    option([
      slot(driving, [card(driving, over18, hash: "dr-1")]),
    ]),
    option([slot(idcard, [], asks: over18)]),
    option([slot(personal, [], asks: over18)]),
  ]),
  one(
    slot(email, [
      card(email, mail1, hash: "e-1"),
      card(email, mail2, hash: "e-2"),
    ]),
  ),
]);

DisclosurePlan drie() => plan([
  choice([
    option([
      slot(passport, [
        card(passport, doc, hash: "pp-1"),
        card(passport, doc2, hash: "pp-2"),
      ]),
    ]),
    option([slot(idcard, [], asks: doc)]),
    option([
      slot(driving, [
        card(driving, [...id3, ("Documentnummer", "5012345678")], hash: "dr-1"),
      ]),
    ]),
  ]),
  one(slot(email, [card(email, mail1, hash: "e-1")])),
]);

DisclosurePlan ontbreekt() => plan([
  one(slot(personal, [card(personal, id3.sublist(0, 2), hash: "pg-1")])),
  one(slot(email, [], asks: mail1)),
]);

DisclosurePlan hotel() => plan([
  choice([
    option([slot(passport, [], asks: doc)]),
    option([slot(idcard, [], asks: doc)]),
    option([slot(driving, [], asks: doc)]),
  ]),
  one(slot(email, [card(email, mail1, hash: "e-1")])),
  one(slot(phone, [card(phone, tel, hash: "t-1")]), opt: true),
]);

DisclosurePlan gemeente() => plan([
  one(slot(personal, [], asks: [...id3, ("Burgerservicenummer", "123456782")])),
  one(slot(email, [], asks: mail1)),
  one(slot(phone, [], asks: tel), opt: true),
]);

const Map<String, List<String>> ja = {
  "Ouder dan 18": ["Ja"],
};

DisclosurePlan speelhal() => plan([
  choice([
    option([slot(passport, [], asks: over18, asked: ja)]),
    option([slot(idcard, [], asks: over18, asked: ja)]),
    option([slot(driving, [], asks: over18, asked: ja)]),
  ]),
]);

/// The address in the app says Utrecht; Rijnstad is asked.
DisclosurePlan parkeren() => plan([
  one(
    slot(
      address,
      [],
      asks: [("Woonplaats", "Rijnstad")],
      asked: {
        "Woonplaats": ["Rijnstad"],
      },
    ),
  ),
]);

List<Credential> parkerenWallet() => [
  walletCard(address, [("Woonplaats", "Utrecht")], hash: "a-w"),
];

DisclosurePlan verlopen() => plan([
  choice([
    option([
      slot(passport, [
        card(passport, doc, reason: UnusableReason.expired, hash: "pp-x"),
      ]),
    ]),
    option([slot(idcard, [], asks: doc)]),
    option([slot(driving, [], asks: doc)]),
  ]),
  one(slot(email, [card(email, mail1, hash: "e-1")])),
]);

DisclosurePlan set() =>
    plan([
      one(slot(email, [card(email, mail1, hash: "e-1")])),
    ]).withFirst(
      choice([
        option([
          slot(personal, [card(personal, id3, hash: "pg-1")]),
          slot(address, [], asks: adr),
        ]),
      ]),
    );

DisclosurePlan combinatie() => plan([
  choice([
    option([
      slot(email, [
        card(email, mail1, hash: "e-1"),
        card(email, mail2, hash: "e-2"),
      ]),
      slot(phone, [
        card(phone, tel, hash: "t-1"),
        card(phone, [("Mobiel telefoonnummer", "06 87654321")], hash: "t-2"),
        card(phone, [("Mobiel telefoonnummer", "06 24680135")], hash: "t-3"),
      ]),
    ]),
  ]),
]);

DisclosurePlan toets() => plan([
  choice([
    option([
      slot(personal, [card(personal, id3, hash: "pg-1")]),
      slot(exam, [
        card(exam, [("Toets", "Statistiek 2")], hash: "x-1"),
        card(exam, [("Toets", "Onderzoeksmethoden")], hash: "x-2"),
        card(exam, [("Toets", "Bedrijfseconomie")], hash: "x-3"),
      ]),
    ]),
  ]),
]);

DisclosurePlan opties() {
  final adrSlot = slot(address, [card(address, adr, hash: "a-1")], id: "adr");
  return plan([
    choice([
      option([
        slot(passport, [
          card(passport, doc, hash: "pp-1"),
          card(passport, doc2, hash: "pp-2"),
        ]),
        adrSlot,
      ]),
      option([
        slot(personal, [
          card(personal, [...id3, ...adr], hash: "pg-1"),
        ]),
      ]),
      option([slot(driving, [], asks: doc), adrSlot]),
    ]),
  ]);
}

DisclosurePlan meerdere() => plan([
  one(
    slot(diploma, [
      card(diploma, [("Opleiding", "HBO Verpleegkunde")], hash: "d-1"),
      card(diploma, [("Opleiding", "Master Zorgmanagement")], hash: "d-2"),
      card(diploma, [("Opleiding", "MBO Verzorgende IG")], hash: "d-3"),
    ], multiple: true),
  ),
  one(slot(email, [card(email, mail1, hash: "e-1")])),
]);

DisclosurePlan tweemaal() {
  List<SelectableCredentialInstance> mails() => [
    card(email, mail1, hash: "e-1"),
    card(email, mail2, hash: "e-2"),
    card(email, mail3, hash: "e-3"),
  ];
  return plan([
    choice([
      option([
        slot(email, mails(), id: "email1"),
        slot(email, mails(), id: "email2"),
      ]),
    ]),
  ]);
}

DisclosurePlan afmaken() => plan([
  choice([
    option([
      slot(email, [
        card(email, mail1, hash: "e-1"),
        card(email, mail2, hash: "e-2"),
      ]),
      slot(phone, [], asks: tel),
    ]),
    option([slot(passport, [], asks: doc)]),
  ]),
]);

DisclosurePlan optiesleeg() {
  final adrSlot = slot(address, [], id: "adr", asks: adr);
  return plan([
    choice([
      option([
        slot(personal, [], asks: [...id3, ...adr]),
      ]),
      option([slot(passport, [], asks: doc), adrSlot]),
      option([slot(driving, [], asks: doc), adrSlot]),
    ]),
  ]);
}

List<DisclosureChoice> _stressSets({required bool filled}) => [
  choice([
    option([
      slot(
        email,
        filled
            ? [
                card(email, mail1, hash: "e-1"),
                card(email, mail2, hash: "e-2"),
                card(email, mail3, hash: "e-3"),
              ]
            : [],
        asks: mail1,
      ),
      slot(
        phone,
        filled
            ? [
                card(phone, tel, hash: "t-1"),
                card(phone, [
                  ("Mobiel telefoonnummer", "06 87654321"),
                ], hash: "t-2"),
              ]
            : [],
        asks: tel,
      ),
    ]),
    option([
      slot(
        iban,
        filled
            ? [
                card(iban, [("IBAN", "NL12 INGB 0001 2345 67")], hash: "b-1"),
                card(iban, [("IBAN", "NL34 RABO 0123 4567 89")], hash: "b-2"),
              ]
            : [],
        asks: [("IBAN", "")],
      ),
      slot(
        passport,
        filled
            ? [
                card(passport, doc, hash: "pp-1"),
                card(passport, doc2, hash: "pp-2"),
              ]
            : [],
        asks: doc,
      ),
    ]),
  ]),
  choice([
    option([
      slot(
        pid,
        filled
            ? [
                card(pid, [("Woonplaats", "Rijnstad")], hash: "p-1"),
                card(pid, [("Woonplaats", "Utrecht")], hash: "p-2"),
              ]
            : [],
        asks: [("Woonplaats", "")],
      ),
      slot(
        driving,
        filled
            ? [
                card(driving, [("Documentnummer", "5012345678")], hash: "dr-1"),
              ]
            : [],
        asks: doc,
      ),
    ]),
    option([
      slot(address, filled ? [card(address, adr, hash: "a-1")] : [], asks: adr),
      slot(idcard, [], asks: doc),
    ]),
  ]),
];

DisclosurePlan stress() => plan(_stressSets(filled: true));

DisclosurePlan stressopt() {
  final sets = _stressSets(filled: true);
  return plan([sets[0], choice(sets[1].options, opt: true)]);
}

DisclosurePlan stressleeg() => plan(_stressSets(filled: false));

DisclosurePlan lang() => plan([
  one(
    slot(personal, [
      card(personal, [
        ("Voornamen", "Maria Josephina Wilhelmina"),
      ], hash: "pg-1"),
    ]),
  ),
  one(
    slot(address, [
      card(address, [("Woonplaats", "’s-Hertogenbosch")], hash: "a-1"),
    ]),
  ),
  one(
    slot(email, [
      card(email, [
        ("E-mailadres", "maria@zorgverzekeraarzuid.example"),
      ], hash: "e-1"),
    ]),
  ),
]);

/// A required card Yivi cannot add.
DisclosurePlan kanniet() => plan([
  one(slot(personal, [card(personal, id3, hash: "pg-1")])),
  one(slot(exam, [], cant: true, asks: [("Toets", "Statistiek 2")])),
]);

/// A revoked card Yivi cannot renew.
DisclosurePlan nietvernieuwen() => plan([
  one(
    slot(exam, [
      card(
        exam,
        [("Toets", "Statistiek 2")],
        reason: UnusableReason.revoked,
        hash: "x-1",
      ),
    ], cant: true),
  ),
]);

DisclosurePlan ingetrokken() => plan([
  one(
    slot(personal, [
      card(personal, id3, reason: UnusableReason.revoked, hash: "pg-1"),
    ], asks: id3),
  ),
  one(slot(email, [card(email, mail1, hash: "e-1")])),
]);

DisclosurePlan eeningetrokken() => plan([
  one(
    slot(email, [
      card(email, mail1, hash: "e-1"),
      card(email, mail2, hash: "e-2"),
      card(email, mail3, reason: UnusableReason.revoked, hash: "e-3"),
    ]),
  ),
]);

DisclosurePlan ontvangen() => plan([
  one(slot(personal, [card(personal, id3, hash: "pg-1")])),
]);

DisclosurePlan nietsnodig() => plan([
  one(slot(email, [card(email, mail1, hash: "e-1")]), opt: true),
  one(slot(phone, [], asks: tel), opt: true),
]);

/// What the issuer gives has another value than is asked.
DisclosurePlan verkeerd() => plan([
  one(
    slot(
      address,
      [],
      asks: [("Woonplaats", "Rijnstad")],
      asked: {
        "Woonplaats": ["Rijnstad"],
      },
    ),
  ),
]);

DisclosurePlan alleenkaartje() => plan([
  one(slot(study, [card(study, const [], hash: "s-1")])),
  one(slot(email, [card(email, mail1, hash: "e-1")])),
]);

/// One query (email) in two credential sets: A = [email] or [mobile], B =
/// [email, iban].
DisclosurePlan tweesets() {
  List<SelectableCredentialInstance> mails() => [
    card(email, mail1, hash: "e-1"),
    card(email, mail2, hash: "e-2"),
    card(email, mail3, hash: "e-3"),
  ];
  return plan([
    choice([
      option([slot(email, mails(), id: "mail")]),
      option([
        slot(phone, [card(phone, tel, hash: "t-1")]),
      ]),
    ]),
    choice([
      option([
        slot(email, mails(), id: "mail"),
        slot(iban, [
          card(iban, [("IBAN", "NL12")], hash: "b-1"),
          card(iban, [("IBAN", "NL34")], hash: "b-2"),
        ]),
      ]),
    ]),
  ]);
}

/// claim_sets: two cards of one kind sharing different fields.
DisclosurePlan claimsets() => plan([
  one(
    slot(pid, [
      card(pid, over18, hash: "p-1"),
      card(pid, [("Geboortedatum", "12 maart 1991")], hash: "p-2"),
    ]),
  ),
]);

DisclosurePlan bewaren() => plan([
  one(
    slot(driving, [
      card(
        driving,
        [
          ("Achternaam", "de Vries"),
          ("Documentnummer", "5012345678"),
          ("Geboortedatum", "12 maart 1991"),
        ],
        keep: {"Achternaam", "Documentnummer"},
        hash: "dr-1",
      ),
    ]),
  ),
  one(
    slot(phone, [
      card(phone, tel, keep: {"Mobiel telefoonnummer"}, hash: "t-1"),
    ]),
    opt: true,
  ),
]);

DisclosurePlan keten() => plan([
  one(slot(personal, [card(personal, id3, hash: "pg-1")])),
]);

DisclosurePlan waarden() => plan([
  one(
    slot(
      pid,
      [],
      asks: [("Land", ""), ("Ouder dan 18", "")],
      asked: {
        "Land": ["NL", "BE", "LU"],
        "Ouder dan 18": ["Ja"],
      },
    ),
  ),
  one(slot(email, [card(email, mail1, hash: "e-1")])),
]);

DisclosurePlan waardenveel() => plan([
  one(
    slot(
      address,
      [],
      asks: [("Provincie", "")],
      asked: {
        "Provincie": [
          "Gelderland",
          "Overijssel",
          "Flevoland",
          "Drenthe",
          "Utrecht",
          "Groningen",
          "Friesland",
        ],
      },
    ),
  ),
]);

DisclosurePlan waardentelt() => plan([
  one(
    slot(
      address,
      [],
      asks: [("Woonplaats", "")],
      asked: {
        "Woonplaats": ["Rijnstad", "Havenstad", "Dijkdorp"],
      },
    ),
  ),
]);

/// Three EU identities in the app (NL, BE, FR); only NL and BE are allowed, so
/// irmago sends two candidates.
DisclosurePlan waardenkeuze() => plan([
  one(
    slot(pid, [
      card(
        pid,
        [("Land", "NL")],
        asked: {
          "Land": ["NL", "BE", "LU"],
        },
        hash: "p-nl",
      ),
      card(
        pid,
        [("Land", "BE")],
        asked: {
          "Land": ["NL", "BE", "LU"],
        },
        hash: "p-be",
      ),
    ]),
  ),
]);

DisclosurePlan genest() => plan([
  one(
    slot(pid, [
      card(pid, [
        ("Voornaam", "Sanne"),
        (
          "Adres",
          <Row>[
            ("Straat", "Lindelaan 12"),
            ("Land", <Row>[("Code", "NL")]),
          ],
        ),
        ("Nationaliteiten", <String>["Nederlandse", "Belgische"]),
      ], hash: "p-1"),
    ]),
  ),
  one(slot(email, [card(email, mail1, hash: "e-1")])),
]);

/// Two study cards that differ only deep inside a list.
DisclosurePlan diepgenest() => plan([
  one(
    slot(study, [
      card(study, [
        (
          "Faculteiten",
          <List<Row>>[
            [("Naam", "Techniek"), ("Decaan", "prof. dr. A. Jansen")],
          ],
        ),
      ], hash: "s-1"),
      card(study, [
        (
          "Faculteiten",
          <List<Row>>[
            [("Naam", "Techniek"), ("Decaan", "prof. dr. B. Smit")],
          ],
        ),
      ], hash: "s-2"),
      card(study, [
        (
          "Faculteiten",
          <List<Row>>[
            [("Naam", "Techniek"), ("Decaan", "prof. dr. A. Jansen")],
          ],
        ),
      ], hash: "s-3"),
    ]),
  ),
]);

DisclosurePlan rijbewijs() => plan([
  one(
    slot(driving, [
      card(driving, [("Achternaam", "de Vries")], hash: "dr-1"),
    ]),
  ),
  one(slot(phone, [card(phone, tel, hash: "t-1")]), opt: true),
]);

DisclosurePlan fotokeuze() => plan([
  choice([
    option([
      slot(passport, [
        card(passport, [("Pasfoto", "p1")], hash: "pp-1"),
        card(passport, [("Pasfoto", "p2")], hash: "pp-2"),
      ]),
    ]),
    option([
      slot(driving, [
        card(driving, [("Pasfoto", "p1")], hash: "dr-1"),
      ]),
    ]),
    option([
      slot(idcard, [], asks: [("Pasfoto", "")]),
    ]),
  ]),
  one(slot(email, [card(email, mail1, hash: "e-1")])),
]);

/// A log entry of a share with [requestor] at [at].
LogInfo share(String requestor, DateTime at) => LogInfo(
  type: LogType.disclosure,
  time: at,
  issuanceLog: null,
  disclosureLog: DisclosureLog(
    protocol: Protocol.irma,
    credentials: const [],
    verifier: party(requestor),
  ),
  signedMessageLog: null,
  removalLog: null,
);

extension on DisclosurePlan {
  /// This plan with [c] as its first choice.
  DisclosurePlan withFirst(DisclosureChoice c) =>
      DisclosurePlan(choices: [c, ...choices]);
}
