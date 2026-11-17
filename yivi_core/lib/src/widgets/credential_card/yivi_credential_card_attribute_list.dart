import "dart:math";

import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:material_ui/material_ui.dart";

import "../../models/credential.dart";
import "../../providers/credential_field_search.dart";
import "../../theme/theme.dart";
import "../../theme/yivi_motion.dart";
import "../../theme/yivi_palette.dart";
import "../../theme/yivi_space.dart";
import "../../util/i18n.dart";
import "../base64_image.dart";
import "../search_mark.dart";
import "../status_chip.dart";
import "../translated_text.dart";
import "attribute_groups/attribute_group.dart";
import "attribute_groups/attribute_group_registry.dart";
import "attribute_groups/attribute_value_formatting.dart";
import "attribute_photo.dart";
import "models/credential_card_layout.dart";

part "attribute_list/attribute_nested.dart";
part "attribute_list/attribute_rows.dart";
part "attribute_list/attribute_tree.dart";
part "attribute_list/value_tag.dart";

/// How `overNN` age attributes are listed.
enum AgeDisplay {
  /// One row per attribute, like any other.
  perAttribute,

  /// One row with the highest age that is true and the lowest that is false,
  /// and a link that expands it into one chip per age.
  collapsed,
}

class YiviCredentialCardAttributeList extends StatelessWidget {
  final List<Attribute> attributes;
  final List<Attribute>? compareTo;

  /// When true, each leaf/primarray row draws a 1px horizontal divider at
  /// its bottom (suppressed on the last row of any parent group).
  final bool showDividers;

  /// Credential type id; selects the attribute group renderers.
  final String? credentialId;

  /// Overrides the registry lookup for [credentialId] (tests).
  final List<AttributeGroupRenderer>? renderers;

  /// The attributes are being shared (a disclosure), not the whole credential.
  final bool disclosure;
  final AgeDisplay ageDisplay;
  final CredentialCardLayout layout;

  /// Claim paths (see [claimPathKey]) whose value does not match what is
  /// needed: they are shown in the error colour.
  final Set<String> mismatched;

  /// Claim paths whose value is exactly what is asked for: shown in the
  /// success colour.
  final Set<String> matched;

  /// A tag beside a [matched] value ("✓ Exactly what they ask"), and beside
  /// a [mismatched] one ("Asked: …").
  final String? matchedTag;
  final String? mismatchedTag;

  /// A single value whose label is this (the card's name, "Email address"
  /// on the card "Email address") is shown without its label.
  final String? hideLabel;

  /// The field a search found the card by (a claim path key): its row is lit,
  /// with the searched text ([foundQuery]) marked, and carries [foundKey] so
  /// the screen can bring it into view.
  final String? found;
  final String foundQuery;
  final GlobalKey? foundKey;
  // The claim paths start with an mso_mdoc namespace: who defined the data
  // element, not a part of the credential, so it never gets a level.
  final bool namespaced;

  const YiviCredentialCardAttributeList(
    this.attributes, {
    this.compareTo,
    this.showDividers = false,
    this.credentialId,
    this.renderers,
    this.disclosure = false,
    this.ageDisplay = AgeDisplay.perAttribute,
    this.layout = CredentialCardLayout.standard,
    this.mismatched = const {},
    this.matched = const {},
    this.matchedTag,
    this.mismatchedTag,
    this.hideLabel,
    this.found,
    this.foundQuery = "",
    this.foundKey,
    this.namespaced = false,
  });

  @override
  Widget build(BuildContext context) {
    final groups = <_ClaimedGroup>[];
    var remaining = attributes;
    for (final renderer
        in renderers ?? attributeGroupRenderers[credentialId] ?? const []) {
      final group = renderer.claim(remaining, compareTo: compareTo);
      if (group == null) continue;
      final claimedKeys = {
        for (final a in group.claimed) claimPathKey(a.claimPath),
      };
      assert(() {
        final offered = {for (final a in remaining) claimPathKey(a.claimPath)};
        return offered.containsAll(claimedKeys);
      }(), "${renderer.runtimeType} claimed an attribute it was not offered");
      final firstIndex = attributes.indexWhere(
        (a) => claimedKeys.contains(claimPathKey(a.claimPath)),
      );
      groups.add(
        _ClaimedGroup(group, firstIndex < 0 ? attributes.length : firstIndex),
      );
      remaining = remaining
          .where((a) => !claimedKeys.contains(claimPathKey(a.claimPath)))
          .toList();
    }

    // Images end up last on every level through _valuesFirst.
    final tree = _buildTree(
      remaining,
      compareTo: compareTo,
      namespaced: namespaced,
      mismatched: mismatched,
      matched: matched,
      found: found == null
          ? null
          : (claimKey: found!, key: foundKey, query: foundQuery),
    );
    _insertGroups(tree.children, groups, attributes);
    // Comparing against another credential needs every attribute on its own row.
    if (ageDisplay == AgeDisplay.collapsed && compareTo == null) {
      _collapseAges(tree.children);
    }
    final ctx = _Ctx(
      // Shared or compared values are never folded away.
      foldable: !disclosure && compareTo == null,
      showDividers: showDividers,
      disclosure: disclosure,
      layout: layout,
      matchedTag: matchedTag,
      mismatchedTag: mismatchedTag,
      hideLabel: attributes.length == 1 ? hideLabel : null,
    );
    return _NestedList(nodes: _normalize(tree.children), ctx: ctx);
  }
}
