import "../models/schemaless/schemaless_events.dart" as schemaless;
import "../widgets/credential_card/card_art/builtin_card_templates.dart";
import "../widgets/credential_card/card_art/card_art_support.dart";

/// The one value shown next to a credential's name so you can tell two
/// instances of the same type apart (two email addresses, two bank accounts).
sealed class InstanceHint {
  const InstanceHint();
}

/// A value taken from the credential's own attributes.
class ValueHint extends InstanceHint {
  final String text;
  const ValueHint(this.text);
}

/// Nothing usable: fall back to the date the credential was added.
class AddedHint extends InstanceHint {
  final DateTime date;
  const AddedHint(this.date);
}

/// Nothing usable and no issuance date.
class NoHint extends InstanceHint {
  const NoHint();
}

/// Identifiers that should not sit in an overview anyone can glance at.
/// Matched against the last name segment of the claim path, lowercased.
const _denyList = {
  "bsn",
  "bsnnumber",
  "documentnumber",
  "document_number",
  "personal_administrative_number",
  "administrative_number",
};

bool _allowed(schemaless.Attribute a) {
  final value = a.value;
  if (value == null) return false;
  if (value.type == schemaless.AttributeType.boolean ||
      value.type == schemaless.AttributeType.image ||
      value.type == schemaless.AttributeType.base64Image) {
    return false;
  }
  if (attributeText(value) == null) return false;
  final name = a.claimPath.lastWhere(
    (seg) => seg is String,
    orElse: () => "",
  ) as String;
  return !_denyList.contains(name.toLowerCase());
}

/// Works out the hint for [credential], comparing it with the other
/// credentials the user holds ([all], which may include [credential]):
///
/// 1. Look only at instances of the same type.
/// 2. An SD-JWT VC with an issuer card template uses the first claim the
///    template shows (`svg_id`), so the text and the card art agree.
/// 3. A credential with a card Yivi ships uses the main value at the top of
///    that card (the name on a passport, not its document type), unless
///    another instance shows the same.
/// 4. With several instances, take the first allowed attribute whose value
///    differs between them; with one instance, the first allowed attribute.
/// 5. Skip images, yes/no values, empty values and deny-listed identifiers.
/// 6. Nothing left: the date it was added.
InstanceHint instanceHintFor(
  schemaless.Credential credential,
  Iterable<schemaless.Credential> all,
) {
  final allowed = credential.attributes.where(_allowed).toList();

  final hasTemplate =
      credential.display?.svgTemplates.isNotEmpty ?? false;
  if (hasTemplate) {
    final shown = allowed.where((a) => a.svgId != null);
    if (shown.isNotEmpty) return ValueHint(attributeText(shown.first.value)!);
  }

  final siblings = all
      .where(
        (c) =>
            c.credentialId == credential.credentialId &&
            c.hash != credential.hash,
      )
      .toList();

  final header = _headerText(credential);
  if (header != null && !siblings.any((s) => _headerText(s) == header)) {
    return ValueHint(header);
  }

  if (siblings.isEmpty) {
    if (allowed.isNotEmpty) return ValueHint(attributeText(allowed.first.value)!);
  } else {
    for (final a in allowed) {
      final key = schemaless.Attribute.pathKey(a.claimPath);
      final mine = attributeText(a.value);
      final differs = siblings.any((s) {
        final other = s.attributes.where(
          (b) => schemaless.Attribute.pathKey(b.claimPath) == key,
        );
        return other.isEmpty || attributeText(other.first.value) != mine;
      });
      if (differs) return ValueHint(mine!);
    }
  }

  final issued = credential.issuanceDate;
  if (issued != null) {
    return AddedHint(DateTime.fromMillisecondsSinceEpoch(issued * 1000));
  }
  return const NoHint();
}

/// The main value at the top of [credential]'s built-in card, as the card
/// shows it; null without one, or when none of it may be shown.
String? _headerText(schemaless.Credential credential) {
  final text = builtinHeaderAttributes(credential)
      .where(_allowed)
      .map((a) => attributeText(a.value)!.trim())
      .where((t) => t.isNotEmpty)
      .join(" ");
  return text.isEmpty ? null : text;
}
