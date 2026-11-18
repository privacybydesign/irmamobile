import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../models/credential.dart";
import "../../search/credential_field_search.dart";
import "../../search/credentials_search.dart";
import "../../widgets/credential_card/attribute_groups/attribute_group.dart";
import "../../widgets/credential_card/attribute_groups/attribute_value_formatting.dart";

/// What the Data search looks in, made once for a set of cards: each card's
/// name with its hint, its issuer, and its fields as the card shows them.
/// It needs a BuildContext to format the values, so it is not a provider;
/// the tab keeps one ([WalletSearchCache]).
class WalletSearchIndex {
  final List<String> _order;
  final List<SearchEntry> _entries;
  final Map<String, List<SearchField>> _fields;

  WalletSearchIndex._(this._order, this._entries, this._fields);

  /// [hintTexts]: each card's instance hint, as the rows show it.
  factory WalletSearchIndex.of(
    BuildContext context,
    List<Credential> cards,
    Map<String, String> hintTexts,
  ) => WalletSearchIndex._(
    [for (final c in cards) c.hash],
    [
      for (final c in cards)
        SearchEntry(
          hash: c.hash,
          credentialType: normaliseForSearch("${c.name} ${hintTexts[c.hash]}"),
          issuerName: normaliseForSearch(c.issuer.name),
        ),
    ],
    {for (final c in cards) c.hash: _searchFields(context, c)},
  );

  /// The cards [query] finds, best first, each with the fields it matched.
  List<CardSearchResult> search(String query) => rankCards(
    order: _order,
    byName: [for (final e in searchCredentials(_entries, query)) e.hash],
    fields: _fields,
    query: query,
  );

  /// The fields of [credential] the search looks in: every attribute with a
  /// value, by its label and its value as the card shows it. Yes/no values
  /// and images are found by their label only.
  static List<SearchField> _searchFields(
    BuildContext context,
    Credential credential,
  ) => [
    for (final a in credential.attributes)
      if (a.value case final value? when value.hasConcreteValue)
        SearchField(
          claimKey: claimPathKey(a.claimPath),
          label: a.effectiveDisplayName,
          value: switch (value.type) {
            AttributeType.string ||
            AttributeType.integer => formatAttributeValue(context, value),
            _ => null,
          },
        ),
  ];
}

/// The tab's [WalletSearchIndex], made again only when the cards, their
/// hints or the language change.
class WalletSearchCache {
  WalletSearchIndex? _index;
  List<Credential>? _cards;
  Map<String, String>? _hintTexts;
  Locale? _locale;

  WalletSearchIndex indexFor(
    BuildContext context,
    List<Credential> cards,
    Map<String, String> hintTexts,
  ) {
    final locale = FlutterI18n.currentLocale(context);
    final index = _index;
    if (index != null &&
        identical(cards, _cards) &&
        _sameTexts(hintTexts, _hintTexts!) &&
        locale == _locale) {
      return index;
    }
    _cards = cards;
    _hintTexts = hintTexts;
    _locale = locale;
    return _index = WalletSearchIndex.of(context, cards, hintTexts);
  }

  static bool _sameTexts(Map<String, String> a, Map<String, String> b) =>
      a.length == b.length && a.entries.every((e) => b[e.key] == e.value);
}
