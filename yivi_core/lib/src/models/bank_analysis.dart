import "translated_value.dart";

/// Where the analysis of a bank connection is, as reported by the PSD2 issuer.
enum BankAnalysisStatus { categorizing, ready, failed }

/// One card the analysis can add to the wallet, with its values.
class AnalysisCredential {
  /// Which kind of card this is, e.g. "income". See [AnalysisDefinitions].
  final String key;
  final Map<String, String> attributes;

  const AnalysisCredential({required this.key, required this.attributes});

  factory AnalysisCredential.fromJson(
    Map<String, dynamic> json,
  ) => AnalysisCredential(
    key: json["key"] as String,
    attributes: {
      for (final MapEntry(:key, :value)
          in (json["attributes"] as Map<String, dynamic>? ?? const {}).entries)
        key: value.toString(),
    },
  );
}

class BankAnalysis {
  final BankAnalysisStatus status;

  /// Identifies the analysis at the issuer.
  final String job;

  /// Why the analysis failed, as an error code of the issuer.
  final String error;
  final List<AnalysisCredential> credentials;

  const BankAnalysis({
    required this.status,
    this.job = "",
    this.error = "",
    this.credentials = const [],
  });

  factory BankAnalysis.fromJson(Map<String, dynamic> json) => BankAnalysis(
    status: switch (json["status"]) {
      "ready" => BankAnalysisStatus.ready,
      "failed" => BankAnalysisStatus.failed,
      _ => BankAnalysisStatus.categorizing,
    },
    job: json["job"] as String? ?? "",
    error: json["error"] as String? ?? "",
    credentials: [
      for (final c in json["credentials"] as List<dynamic>? ?? const [])
        AnalysisCredential.fromJson(c as Map<String, dynamic>),
    ],
  );
}

class AnalysisAttributeDefinition {
  final String id;
  final TranslatedValue name;

  /// Whether the value is an amount of money: a monthly average in euros.
  final bool isAmount;

  const AnalysisAttributeDefinition({
    required this.id,
    required this.name,
    required this.isAmount,
  });

  factory AnalysisAttributeDefinition.fromJson(Map<String, dynamic> json) =>
      AnalysisAttributeDefinition(
        id: json["id"] as String,
        name: _translated(json["name"]),
        // amounts are the attributes that come from categorized transactions
        isAmount: (json["e1"] as String? ?? "").isNotEmpty,
      );
}

class AnalysisCredentialDefinition {
  final String key;
  final TranslatedValue name;
  final TranslatedValue description;
  final List<AnalysisAttributeDefinition> attributes;

  const AnalysisCredentialDefinition({
    required this.key,
    required this.name,
    required this.description,
    required this.attributes,
  });

  factory AnalysisCredentialDefinition.fromJson(Map<String, dynamic> json) =>
      AnalysisCredentialDefinition(
        key: json["key"] as String,
        name: _translated(json["name"]),
        description: _translated(json["description"]),
        attributes: [
          for (final a in json["attributes"] as List<dynamic>? ?? const [])
            AnalysisAttributeDefinition.fromJson(a as Map<String, dynamic>),
        ],
      );
}

/// The names of the cards and their values, in the order to show them. They
/// come from the issuer, which is where the cards are defined.
class AnalysisDefinitions {
  final List<AnalysisCredentialDefinition> credentials;

  /// The values every card about amounts has: the period they are about.
  final List<AnalysisAttributeDefinition> periodAttributes;

  const AnalysisDefinitions({
    required this.credentials,
    this.periodAttributes = const [],
  });

  factory AnalysisDefinitions.fromJson(Map<String, dynamic> json) =>
      AnalysisDefinitions(
        credentials: [
          for (final c in json["credentials"] as List<dynamic>? ?? const [])
            AnalysisCredentialDefinition.fromJson(c as Map<String, dynamic>),
        ],
        periodAttributes: [
          for (final a
              in json["period_attributes"] as List<dynamic>? ?? const [])
            AnalysisAttributeDefinition.fromJson(a as Map<String, dynamic>),
        ],
      );
}

TranslatedValue _translated(Object? json) => TranslatedValue({
  if (json is Map<String, dynamic>)
    for (final MapEntry(:key, :value) in json.entries) key: value.toString(),
});

/// The cards of one kind, with their definition: one card for most kinds,
/// one per account for bank accounts.
class AnalysisCredentialGroup {
  final AnalysisCredentialDefinition definition;
  final List<AnalysisCredential> credentials;

  const AnalysisCredentialGroup({
    required this.definition,
    required this.credentials,
  });

  String get key => definition.key;

  /// The amounts that are not zero, as (definition, whole euros per month).
  List<(AnalysisAttributeDefinition, int)> amountsOf(
    AnalysisCredential credential,
  ) => [
    for (final attribute in definition.attributes)
      if (attribute.isAmount)
        if (int.tryParse(credential.attributes[attribute.id] ?? "")
            case final amount? when amount != 0)
          (attribute, amount),
  ];

  bool get hasAmounts => definition.attributes.any((a) => a.isAmount);

  /// Whether there is nothing to tell: a card about amounts that are all
  /// zero. Such a card is not selected by default.
  bool get isEmpty =>
      hasAmounts && credentials.every((c) => amountsOf(c).isEmpty);
}

/// Groups [credentials] per kind, in the order of [definitions]. Kinds
/// without a definition are left out: there is no way to show them.
List<AnalysisCredentialGroup> groupAnalysisCredentials(
  List<AnalysisCredential> credentials,
  AnalysisDefinitions definitions,
) => [
  for (final definition in definitions.credentials)
    if (credentials.where((c) => c.key == definition.key).toList()
        case final ofKind when ofKind.isNotEmpty)
      AnalysisCredentialGroup(definition: definition, credentials: ofKind),
];
