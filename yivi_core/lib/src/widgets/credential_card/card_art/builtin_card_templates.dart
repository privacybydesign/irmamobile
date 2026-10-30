import "../../../../package_name.dart";
import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "builtin_card_svgs.dart";

/// Card templates Yivi ships for credentials whose issuer has no design of
/// its own: the PbDF scheme, the demo scheme and the test credentials of the
/// OpenID4VCI and mdoc flows. They use the same SVG + `{{placeholder}}`
/// format issuers use for SD-JWT VC `svg_templates`. The top 64 points of
/// each card hold a pictogram, the credential's name and its main value,
/// with a small illustration on the right: that is what a card shows in the
/// stack. The card is one colour from the top down, with no band behind the
/// header, so the corners of the next card in the stack show the same colour.
/// Each card has a typeface of its own, bundled under `fonts/cards/`.
///
/// Placeholders, filled by `CredentialCardArt`:
/// - `{{<attribute id>}}`: the attribute's value (`{{email}}`, `{{photo}}`);
///   for SD-JWT and mdoc credentials the claim's name (`{{given_name}}`);
/// - `{{label.<attribute id>}}`: the attribute's name, in the app's language;
/// - `{{yivi.name}}` and `{{yivi.issuer}}`: the credential's name and issuer.
///
/// [attributeIds] are the credential's attribute ids, for a template that
/// only fits one version of a credential type (see [_requires]).
schemaless.SvgCardTemplate? builtinCardTemplate(
  String credentialId, {
  Iterable<String>? attributeIds,
}) {
  final key = _cardKey(credentialId);
  if (key == null) return null;
  final required = _requires[key];
  if (required != null &&
      attributeIds != null &&
      !attributeIds.contains(required)) {
    return null;
  }
  return schemaless.SvgCardTemplate(
    svg: _svgs.putIfAbsent(key, () => _svg(builtinCardSvgs[key]!)),
    orientation: "landscape",
  );
}

/// The full SVG of each template, built on first use.
final _svgs = <String, String>{};

String _svg(String body) =>
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 358 226" width="358" height="226">'
    '${body.replaceAll("§", "packages/$packageName/")}</svg>';

/// The template of [credentialId], if Yivi has one. Staging credentials
/// (`pbdf-staging.`) share their production template.
String? _cardKey(String credentialId) {
  final id = credentialId.startsWith(_staging)
      ? "pbdf.${credentialId.substring(_staging.length)}"
      : credentialId;
  return _cards[id] ?? _testIssuerCard(id);
}

const _staging = "pbdf-staging.";

/// The SD-JWT credentials of the OpenID4VCI test issuers, by the last part
/// of their `vct` (`…/vct/email`); each test issuer has its own path.
String? _testIssuerCard(String vct) {
  final uri = Uri.tryParse(vct);
  if (uri == null || uri.host != "veramo-issuer.openid4vc.staging.yivi.app") {
    return null;
  }
  final segments = uri.pathSegments;
  if (segments.length < 2 || segments[segments.length - 2] != "vct") {
    return null;
  }
  return const {
    "email": "email",
    "phone": "mobile",
    "organization": "org",
    "statuslist": "statuslist",
  }[segments.last];
}

/// Templates that only fit one version of their credential type: the
/// attribute that version has. Production's deprecated diploma has other
/// attributes than the new one, and keeps the Yivi card.
const _requires = {"diploma": "qualification"};

/// Which template each credential type gets. Types with the same attributes
/// share one (the demo scheme's copies, deprecated predecessors).
const _cards = <String, String>{
  // PbDF
  "pbdf.gemeente.personalData": "personal",
  "pbdf.gemeente.address": "address",
  "pbdf.pbdf.passport": "passport",
  "pbdf.pbdf.idcard": "idcard",
  "pbdf.pbdf.residencepermit": "residence",
  "pbdf.pbdf.drivinglicence": "driving",
  "pbdf.pbdf.ageLimits": "age",
  "pbdf.pbdf.ageVerification": "ageverif",
  "pbdf.pbdf.iban": "iban",
  "pbdf.pbdf.ideal": "iban",
  "pbdf.pbdf.idin": "idin",
  "pbdf.pbdf.big": "big",
  "pbdf.pbdf.surfnet-2": "surf",
  "pbdf.pbdf.surfnet": "surf",
  "pbdf.pbdf.linkedin": "linkedin",
  "pbdf.pbdf.yivitube": "yivitube",
  "pbdf.pbdf.irmatube": "yivitube",
  "pbdf.pbdf.vog": "vog",
  "pbdf.pbdf.diploma": "diploma",
  "pbdf.pbdf.microsoftEntraIdReference": "entra",
  "pbdf.pbdf.facebook": "facebook",
  "pbdf.pbdf.twitter": "twitter",
  "pbdf.pbdf.email": "email",
  "pbdf.pbdf.mobilenumber": "mobile",
  "pbdf.sidn-pbdf.email": "email",
  "pbdf.sidn-pbdf.mobilenumber": "mobile",
  "pbdf.sidn-pbdf.irma": "appid",
  "pbdf.sidn-pbdf.uniqueid": "uniqueid",
  "pbdf.signicat.kvkTradeRegister": "kvk",
  // Demo scheme: the copies of PbDF types
  "irma-demo.gemeente.personalData": "personal",
  "irma-demo.gemeente.address": "address",
  "irma-demo.pbdf.drivinglicence": "driving",
  "irma-demo.pbdf.linkedin": "linkedin",
  "irma-demo.pbdf.surfnet-2": "surf",
  "irma-demo.pbdf.mobilenumber": "mobile",
  "irma-demo.pbdf.facebook": "facebook",
  "irma-demo.pbdf.twitter": "twitter",
  "irma-demo.sidn-pbdf.email": "email",
  "irma-demo.sidn-pbdf.mobilenumber": "mobile",
  "irma-demo.sidn-pbdf.uniqueid": "uniqueid",
  "irma-demo.idin.idin": "idin",
  "irma-demo.idin.ageLimits": "age",
  "irma-demo.ideal.ideal": "iban",
  "irma-demo.IRMATube.member": "yivitube",
  // Demo scheme: its own types
  "irma-demo.MijnOverheid.root": "moroot",
  "irma-demo.MijnOverheid.fullName": "moname",
  "irma-demo.MijnOverheid.address": "moaddress",
  "irma-demo.MijnOverheid.ageLower": "moagelow",
  "irma-demo.MijnOverheid.ageHigher": "moagehigh",
  "irma-demo.MijnOverheid.birthCertificate": "mobirth",
  "irma-demo.MijnOverheid.drivinglicense": "molicence",
  "irma-demo.MijnOverheid.idDocument": "moiddoc",
  "irma-demo.stemmen.stempas": "stempas",
  "irma-demo.ivido.login": "ivido",
  "irma-demo.nuts.agb": "nutsagb",
  "irma-demo.enablenow.alimony": "enalimony",
  "irma-demo.enablenow.bankaccount": "enbankaccount",
  "irma-demo.enablenow.cash": "encash",
  "irma-demo.enablenow.essential": "enessential",
  "irma-demo.enablenow.expense": "enexpense",
  "irma-demo.enablenow.gambling": "engambling",
  "irma-demo.enablenow.housing": "enhousing",
  "irma-demo.enablenow.income": "enincome",
  "irma-demo.enablenow.insurance": "eninsurance",
  "irma-demo.enablenow.investment": "eninvestment",
  "irma-demo.enablenow.lifestyle": "enlifestyle",
  "irma-demo.enablenow.loan": "enloan",
  "irma-demo.enablenow.other": "enother",
  "irma-demo.enablenow.subsidy": "ensubsidy",
  "irma-demo.enablenow.tax": "entax",
  "irma-demo.enablenow.transport": "entransport",
  // mdoc, by doctype
  "eu.europa.ec.eudi.pid.1": "pid",
  "org.iso.18013.5.1.mDL": "mdl",
  "eu.europa.ec.av.1": "av",
};

/// Every credential type with a built-in card, for tests.
Iterable<String> get builtinCardCredentialIds => _cards.keys;

/// Attributes that hold a picture. A template draws them with
/// `<image href="{{…}}">`, so they need a valid image even when empty.
const builtinImageSlots = {"photo"};

/// Claims a template knows under another name: the test issuer's phone
/// credential has `phone_number` where the mobile number card has
/// `mobilenumber`.
const _aliases = {"phone_number": "mobilenumber"};

/// The values a built-in template is filled with: each attribute's value and
/// name by its attribute id (the last step of its claim path), the
/// credential's name and issuer, and a transparent picture for an image slot
/// the credential leaves empty. [text] turns an attribute into the text (or
/// image URI) it shows.
Map<String, String> builtinTemplateValues(
  schemaless.Credential credential,
  String Function(schemaless.Attribute attribute) text,
) {
  final values = {
    for (final id in builtinImageSlots) id: transparentPixel,
    "yivi.name": credential.name,
    "yivi.issuer": credential.issuer.name,
  };
  for (final a in credential.attributes) {
    if (a.claimPath.isEmpty) continue;
    final claim = "${a.claimPath.last}";
    final value = text(a);
    for (final id in {claim, ?_aliases[claim]}) {
      if (value.isNotEmpty || !builtinImageSlots.contains(id)) {
        values[id] = value;
      }
      values["label.$id"] = a.effectiveDisplayName;
    }
  }
  return values;
}

/// The attributes of [credential]'s built-in card that make up its main
/// value: the line under the credential's name at the top of the card
/// (`{{firstName}} {{lastName}}`, `{{street}} {{houseNumber}}`), in the
/// order the card shows them. Empty without a built-in card.
List<schemaless.Attribute> builtinHeaderAttributes(
  schemaless.Credential credential,
) {
  final template = builtinCardTemplate(
    credential.credentialId,
    attributeIds: credential.attributes
        .where((a) => a.claimPath.isNotEmpty)
        .map((a) => "${a.claimPath.last}"),
  );
  if (template == null) return const [];
  final ids = _headerIds.putIfAbsent(
    template.svg,
    () => _headerIdsOf(template.svg),
  );
  return [
    for (final id in ids)
      for (final a in credential.attributes)
        if (a.claimPath.isNotEmpty &&
            {
              "${a.claimPath.last}",
              ?_aliases["${a.claimPath.last}"],
            }.contains(id))
          a,
  ];
}

final _headerIds = <String, List<String>>{};

/// The attribute placeholders of the text right after `{{yivi.name}}`:
/// every template puts its main value there, under the name.
List<String> _headerIdsOf(String svg) {
  final name = svg.indexOf("{{yivi.name}}");
  if (name < 0) return const [];
  final after = svg.indexOf("</text>", name);
  if (after < 0) return const [];
  final line = RegExp(
    r"<text[^>]*>(.*?)</text>",
    dotAll: true,
  ).firstMatch(svg.substring(after + "</text>".length));
  if (line == null) return const [];
  return [
    for (final m in RegExp(r"\{\{([^}]+)\}\}").allMatches(line.group(1)!))
      if (!m.group(1)!.startsWith("label.") && !m.group(1)!.startsWith("yivi."))
        m.group(1)!,
  ];
}

/// A transparent 1×1 PNG, for an image placeholder without a picture.
const transparentPixel =
    "data:image/png;base64,"
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=";
