import "../../../../package_name.dart";
import "../../../models/schemaless/schemaless_events.dart" as schemaless;

/// Card templates Yivi ships for its own credentials (the PbDF scheme), in
/// the same SVG + `{{placeholder}}` format issuers use for SD-JWT VC
/// `svg_templates`. Each card starts with a 64-point top bar in the type's
/// colour (a pictogram, the credential's name and its main value): that is
/// what a card shows in the stack, so the type and the value that tells
/// cards apart read at a glance. Below it the card is drawn as an object of
/// its type (security paper, a map, a passport page, an envelope, …).
///
/// Placeholders, filled by `CredentialCardArt`:
/// - `{{<attribute id>}}`: the attribute's value (`{{email}}`, `{{photo}}`);
/// - `{{label.<attribute id>}}`: the attribute's name, in the app's language;
/// - `{{yivi.name}}` and `{{yivi.issuer}}`: the credential's name and issuer.
///
/// Production (`pbdf.`) and staging (`pbdf-staging.`) credentials share a
/// template: see [builtinCardTemplate].
schemaless.SvgCardTemplate? builtinCardTemplate(String credentialId) {
  final svg = _templates[_productionId(credentialId)];
  return svg == null
      ? null
      : schemaless.SvgCardTemplate(svg: svg, orientation: "landscape");
}

/// [credentialId] with the staging scheme read as the production one.
String _productionId(String credentialId) => credentialId.startsWith(_staging)
    ? "pbdf.${credentialId.substring(_staging.length)}"
    : credentialId;

const _staging = "pbdf-staging.";

/// Attributes that hold a picture. A template draws them with
/// `<image href="{{…}}">`, so they need a valid image even when empty.
const builtinImageSlots = {"photo"};

/// The values a built-in template is filled with: each attribute's value and
/// name by its attribute id, the credential's name and issuer, and a
/// transparent picture for an image slot the credential leaves empty.
/// [text] turns an attribute into the text (or image URI) it shows.
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
    final id = "${a.claimPath.last}";
    final value = text(a);
    if (value.isNotEmpty || !builtinImageSlots.contains(id)) values[id] = value;
    values["label.$id"] = a.effectiveDisplayName;
  }
  return values;
}

/// A transparent 1×1 PNG, for an image placeholder without a picture.
const transparentPixel =
    "data:image/png;base64,"
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=";

const _display = "packages/$packageName/Alexandria";
const _body = "packages/$packageName/Open Sans";

/// The top bar every template starts with: 64 points high, a gradient from
/// [top] to [bottom], a fine [edge] line under it, a pictogram tile and the
/// credential's name above its main [value]. It is what a card shows in the
/// stack, so it carries the type and the value that tells cards apart.
String _bar({
  required String id,
  required String top,
  required String bottom,
  required String icon,
  required String value,
  String edge = "#FFFFFF",
  String edgeOpacity = "0.2",
  String edgeHeight = "1",
  String tile = "#FFFFFF",
  String tileOpacity = "0.15",
  String tileStrokeOpacity = "0.3",
  String iconColor = "#FFFFFF",
  String labelColor = "#FFFFFF",
  String labelOpacity = "0.75",
}) =>
    '''
<defs><linearGradient id="$id" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="$top"/><stop offset="1" stop-color="$bottom"/></linearGradient></defs>
<rect width="358" height="64" fill="url(#$id)"/>
<rect y="63" width="358" height="$edgeHeight" fill="$edge" fill-opacity="$edgeOpacity"/>
<rect x="18.5" y="16.5" width="31" height="31" rx="10" fill="$tile" fill-opacity="$tileOpacity" stroke="$tile" stroke-opacity="$tileStrokeOpacity"/>
<g transform="translate(22 20)" fill="none" stroke="$iconColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="$icon"/></g>
<text x="62" y="28" font-family="$_body" font-size="10.5" font-weight="700" letter-spacing="0.4" fill="$labelColor" fill-opacity="$labelOpacity">{{yivi.name}}</text>
<text x="62" y="48" font-family="$_display" font-size="17" font-weight="700" fill="#FFFFFF">$value</text>''';

/// A label above its value, on the shared grid of the card bodies.
String _field(num x, num y, String id, String labelColor, String color) =>
    '''
<text x="$x" y="$y" font-family="$_body" font-size="10.5" fill="$labelColor">{{label.$id}}</text>
<text x="$x" y="${y + 18}" font-family="$_body" font-size="15" font-weight="600" fill="$color">{{$id}}</text>''';

/// The issuer in the bottom-left corner, where every card has it.
String _issuer(String color) =>
    '<text x="20" y="214" font-family="$_body" font-size="10" fill="$color">{{yivi.issuer}}</text>';

/// A framed photo with a silhouette behind it, for when there is no photo.
String _photo(String fill, String stroke, String silhouette) =>
    '''
<defs><clipPath id="photo"><rect x="20" y="78" width="56" height="72" rx="9"/></clipPath></defs>
<rect x="20" y="78" width="56" height="72" rx="9" fill="$fill"/>
<g fill="$silhouette"><circle cx="48" cy="104" r="12"/><path d="M29 150 C29 131 39 124 48 124 C57 124 67 131 67 150 Z"/></g>
<image href="{{photo}}" x="20" y="78" width="56" height="72" preserveAspectRatio="xMidYMid slice" clip-path="url(#photo)"/>
<rect x="20" y="78" width="56" height="72" rx="9" fill="none" stroke="$stroke" stroke-width="1.5"/>''';

String _svg(String body) =>
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 358 226" width="358" height="226">$body</svg>';

const _icons = (
  person:
      "M12 4a4 4 0 1 1 0 8a4 4 0 1 1 0-8z M4.5 21c0-4.2 3.4-6.8 7.5-6.8s7.5 2.6 7.5 6.8",
  house: "M4 11 12 4l8 7 M6 9.5V20h12V9.5 M10 20v-5h4v5",
  passport:
      "M7 2.5h10a2 2 0 0 1 2 2v15a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2v-15a2 2 0 0 1 2-2z M12 7a3 3 0 1 1 0 6a3 3 0 1 1 0-6z M9 17h6",
  wheel:
      "M12 3a9 9 0 1 1 0 18a9 9 0 1 1 0-18z M12 9.5a2.5 2.5 0 1 1 0 5a2.5 2.5 0 1 1 0-5z M3.5 11h6 M14.5 11h6 M12 14.5V21",
  age:
      "M4.5 8.5 7 7v10 M10.5 9.5a2 2 0 1 1 4 0a2 2 0 1 1-4 0z M10 14.5a2.5 2.5 0 1 1 5 0a2.5 2.5 0 1 1-5 0z M19 10v4 M17 12h4",
  envelope:
      "M5 5h14a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2z M3.5 6.5 12 13l8.5-6.5",
  phone:
      "M9.5 2.5h5a2.5 2.5 0 0 1 2.5 2.5v14a2.5 2.5 0 0 1-2.5 2.5h-5A2.5 2.5 0 0 1 7 19V5a2.5 2.5 0 0 1 2.5-2.5z M11 18.5h2",
  bank: "M3 9.5 12 4l9 5.5 M5 10v8 M9.5 10v8 M14.5 10v8 M19 10v8 M3 20.5h18",
);

/// Twelve petals round a centre: the rosette of the personal data card.
final _rosette = [
  for (var a = 0; a < 180; a += 15)
    '<ellipse rx="66" ry="17" transform="rotate($a)"/>',
].join();

/// A row of `<` characters, the filler of a machine-readable zone.
final _mrzFill = List.filled(28, "&lt;").join();

final _templates = <String, String>{
  "pbdf.gemeente.personalData": _svg('''
<defs><radialGradient id="pdb" cx="0.35" cy="0.45" r="0.85"><stop offset="0" stop-color="#FBF9F4"/><stop offset="1" stop-color="#EDE6D8"/></radialGradient></defs>
<rect width="358" height="226" fill="url(#pdb)"/>
<g transform="translate(306 150)" fill="none" stroke="#173F6B" stroke-width="1" stroke-opacity="0.12">$_rosette<circle r="30"/><circle r="52"/><circle r="70" stroke-dasharray="2 3"/></g>
<circle cx="306" cy="150" r="13" fill="#173F6B" fill-opacity="0.08"/>
<g fill="none" stroke="#173F6B" stroke-width="0.8"><path d="M0 188 C30 180 60 196 90 188 S150 180 180 188 S240 196 270 188 S330 180 358 188" stroke-opacity="0.2"/><path d="M0 192 C30 184 60 200 90 192 S150 184 180 192 S240 200 270 192 S330 184 358 192" stroke-opacity="0.13"/></g>
${_bar(id: "pdh", top: "#21507F", bottom: "#173D66", icon: _icons.person, value: "{{fullname}}", edgeOpacity: "0.18", tileOpacity: "0.14", tileStrokeOpacity: "0.28", labelOpacity: "0.72")}
${_field(20, 92, "dateofbirth", "#6B7A8F", "#13263F")}
${_field(152, 92, "cityofbirth", "#6B7A8F", "#13263F")}
${_field(20, 134, "nationality", "#6B7A8F", "#13263F")}
${_field(152, 134, "gender", "#6B7A8F", "#13263F")}
${_issuer("#6B7A8F")}'''),

  "pbdf.gemeente.address": _svg('''
<defs><clipPath id="map"><rect x="186" y="80" width="156" height="114" rx="16"/></clipPath></defs>
<rect width="358" height="226" fill="#FBF3EA"/>
<g clip-path="url(#map)">
<rect x="186" y="80" width="156" height="114" fill="#F4E4D3"/>
<rect x="282" y="80" width="60" height="44" rx="6" fill="#D8E6C3"/>
<g fill="#ECD5BF"><rect x="190" y="84" width="40" height="26" rx="5"/><rect x="238" y="84" width="38" height="26" rx="5"/><rect x="190" y="118" width="40" height="34" rx="5"/><rect x="190" y="160" width="40" height="30" rx="5"/><rect x="300" y="132" width="38" height="58" rx="5"/></g>
<path d="M240 190 C 248 166, 272 160, 290 132 S 316 98, 338 86" fill="none" stroke="#A9D3EE" stroke-width="12" stroke-linecap="round"/>
<g stroke="#FFFFFF" stroke-width="5" stroke-linecap="round" fill="none"><path d="M190 114 H338"/><path d="M234 84 V190"/><path d="M280 84 V126"/><path d="M190 156 H292"/></g>
<ellipse cx="258" cy="140" rx="9" ry="3" fill="#000000" fill-opacity="0.15"/>
<path d="M245 112 c0 -17 26 -17 26 0 c0 12 -13 27 -13 27 s-13 -15 -13 -27z" fill="#C2552D"/>
<circle cx="258" cy="112" r="5" fill="#FFFFFF"/>
</g>
<rect x="186.5" y="80.5" width="155" height="113" rx="15.5" fill="none" stroke="#000000" stroke-opacity="0.06"/>
${_bar(id: "adh", top: "#D2683C", bottom: "#B44D27", icon: _icons.house, value: "{{street}} {{houseNumber}}", tileOpacity: "0.16", labelOpacity: "0.78")}
<text x="20" y="102" font-family="$_display" font-size="18" font-weight="700" fill="#3A1A0E">{{zipcode}}</text>
<text x="20" y="126" font-family="$_display" font-size="18" font-weight="700" fill="#3A1A0E">{{city}}</text>
${_field(20, 158, "municipality", "#8A5A43", "#3A1A0E")}
${_issuer("#8A5A43")}'''),

  "pbdf.pbdf.passport": _svg(
    '''
<defs><radialGradient id="ppb" cx="0.7" cy="0.45" r="0.8"><stop offset="0" stop-color="#7E2337"/><stop offset="1" stop-color="#5F1828"/></radialGradient></defs>
<rect width="358" height="226" fill="url(#ppb)"/>
<g fill="none" stroke="#D9B36A" stroke-width="0.9" stroke-opacity="0.2"><path d="M-10 96 Q179 70 368 96"/><path d="M-10 110 Q179 84 368 110"/><path d="M-10 124 Q179 98 368 124"/><path d="M-10 138 Q179 112 368 138"/><path d="M-10 152 Q179 126 368 152"/></g>
<g fill="none" stroke="#D9B36A" stroke-width="1.6" stroke-opacity="0.9"><circle cx="302" cy="116" r="38"/><ellipse cx="302" cy="116" rx="15" ry="38"/><ellipse cx="302" cy="116" rx="28" ry="38"/><path d="M264 116 H340 M269 97 H335 M269 135 H335"/></g>
<circle cx="302" cy="116" r="46" fill="none" stroke="#D9B36A" stroke-opacity="0.35" stroke-dasharray="1.5 3"/>
${_bar(id: "pph", top: "#5E1729", bottom: "#47101E", icon: _icons.passport, value: "{{firstName}} {{lastName}}", edge: "#D9B36A", edgeOpacity: "0.85", edgeHeight: "1.2", tile: "#D9B36A", tileOpacity: "0.16", tileStrokeOpacity: "0.5", iconColor: "#E2C07E", labelColor: "#E2C07E", labelOpacity: "1")}
${_photo("#F3E7D3", "#D9B36A", "#CDB48E")}
${_field(92, 92, "documentNumber", "#E2C07E", "#FFFFFF")}
${_field(92, 130, "dateOfExpiry", "#E2C07E", "#FFFFFF")}
<rect x="0" y="170" width="358" height="56" fill="#000000" fill-opacity="0.26"/>
<g font-family="$_body" font-size="10.5" letter-spacing="1.3" fill="#EADBB8" fill-opacity="0.9"><text x="20" y="192">P&lt;{{country}}$_mrzFill</text><text x="20" y="210">{{documentNumber}}&lt;{{country}}$_mrzFill</text></g>''',
  ),

  "pbdf.pbdf.drivinglicence": _svg('''
<defs><linearGradient id="dlb" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FCE4EC"/><stop offset="1" stop-color="#F0B7CA"/></linearGradient></defs>
<rect width="358" height="226" fill="url(#dlb)"/>
<g fill="none" stroke="#E7A3BA" stroke-width="0.9" stroke-opacity="0.6"><path d="M0 176 C50 160 100 196 150 176"/><path d="M0 184 C50 168 100 204 150 184"/><path d="M0 192 C50 176 100 212 150 192"/></g>
<path d="M140 250 C 205 178, 250 156, 380 118" fill="none" stroke="#FFFFFF" stroke-opacity="0.7" stroke-width="46" stroke-linecap="round"/>
<path d="M140 250 C 205 178, 250 156, 380 118" fill="none" stroke="#DE8AA6" stroke-width="2.5" stroke-dasharray="12 10"/>
${_bar(id: "dlh", top: "#B63664", bottom: "#99264C", icon: _icons.wheel, value: "{{firstName}} {{lastName}}", tileOpacity: "0.16", labelOpacity: "0.78")}
${_photo("#FFFFFF", "#D79AAF", "#D9A7B8")}
${_field(92, 92, "documentNumber", "#8A2349", "#3A1E2A")}
${_field(92, 130, "dateOfExpiry", "#8A2349", "#3A1E2A")}
${_issuer("#8A2349")}'''),

  "pbdf.pbdf.ageLimits": _svg('''
<defs><linearGradient id="agb" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#4C3AA2"/><stop offset="1" stop-color="#8E40A3"/></linearGradient></defs>
<rect width="358" height="226" fill="url(#agb)"/>
<circle cx="330" cy="70" r="90" fill="#FFFFFF" fill-opacity="0.05"/>
<circle cx="20" cy="230" r="70" fill="#FFFFFF" fill-opacity="0.05"/>
${_bar(id: "agh", top: "#42329A", bottom: "#31247A", icon: _icons.age, value: "{{label.over18}}: {{over18}}", edgeOpacity: "0.18", tileOpacity: "0.14", tileStrokeOpacity: "0.28", labelOpacity: "0.72")}
<path d="M44 140 H314" stroke="#FFFFFF" stroke-opacity="0.3" stroke-width="3" stroke-linecap="round"/>
<g font-family="$_display" font-weight="800" text-anchor="middle">
${[
    for (final (x, age, fill) in const [(44, 12, "#5A43AE"), (111, 16, "#6542AF"), (247, 21, "#7B41AA"), (314, 65, "#8640A6")]) '<circle cx="$x" cy="140" r="20" fill="$fill" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="1.5"/><text x="$x" y="145" font-size="13" fill="#FFFFFF">$age</text>',
  ].join()}
<circle cx="179" cy="140" r="26" fill="#FFFFFF"/><text x="179" y="146" font-size="16" fill="#3A2B86">18</text>
</g>
<g font-family="$_body" font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">
${[
    for (final (x, age) in const [(44, 12), (111, 16), (179, 18), (247, 21), (314, 65)]) '<text x="$x" y="186">{{over$age}}</text>',
  ].join()}
</g>
${_issuer("#E3DCF7")}'''),

  "pbdf.sidn-pbdf.email": _svg('''
<rect width="358" height="226" fill="#F5BD48"/>
<polygon points="0,226 152,128 179,146 206,128 358,226" fill="#EDAE30"/>
<polygon points="0,68 179,170 358,68" fill="#000000" fill-opacity="0.07"/>
<polygon points="0,64 179,164 358,64" fill="#F9D37D"/>
<path d="M0 64 L179 164 L358 64" fill="none" stroke="#E6A631" stroke-width="1.5"/>
<g transform="translate(284 76)">
<rect width="54" height="62" rx="3" fill="#FFFFFF"/>
<rect width="54" height="62" rx="3" fill="none" stroke="#F5BD48" stroke-width="4" stroke-dasharray="0.1 6" stroke-linecap="round"/>
<rect x="7" y="7" width="40" height="48" rx="2" fill="#FDF3DA"/>
<text x="27" y="41" text-anchor="middle" font-family="$_display" font-size="28" font-weight="800" fill="#B87A0E">@</text>
</g>
<g fill="none" stroke="#B87A0E" stroke-opacity="0.35" stroke-width="1.3"><path d="M222 92 c8 -5 14 5 22 0 s14 5 22 0"/><path d="M222 100 c8 -5 14 5 22 0 s14 5 22 0"/><path d="M222 108 c8 -5 14 5 22 0 s14 5 22 0"/></g>
${_bar(id: "emh", top: "#C98B14", bottom: "#A86F0A", icon: _icons.envelope, value: "{{email}}", edgeOpacity: "0.22", tileOpacity: "0.18", tileStrokeOpacity: "0.32", labelOpacity: "0.8")}
${_field(20, 194, "domain", "#6A4500", "#2E1E00")}'''),

  "pbdf.sidn-pbdf.mobilenumber": _svg('''
<defs><radialGradient id="mob" cx="0.82" cy="0.7" r="0.9"><stop offset="0" stop-color="#2A9E6B"/><stop offset="1" stop-color="#1A7E52"/></radialGradient></defs>
<rect width="358" height="226" fill="url(#mob)"/>
<g fill="none" stroke="#FFFFFF" stroke-linecap="round" stroke-width="5"><path d="M330 96 a44 44 0 0 1 0 60" stroke-opacity="0.22"/><path d="M344 82 a66 66 0 0 1 0 88" stroke-opacity="0.14"/><path d="M254 96 a44 44 0 0 0 0 60" stroke-opacity="0.22"/><path d="M240 82 a66 66 0 0 0 0 88" stroke-opacity="0.14"/></g>
<rect x="262" y="78" width="60" height="112" rx="14" fill="#0E5537"/>
<rect x="262" y="78" width="60" height="112" rx="14" fill="none" stroke="#FFFFFF" stroke-opacity="0.45" stroke-width="1.5"/>
<rect x="268" y="90" width="48" height="88" rx="7" fill="#33B07A"/>
<rect x="284" y="83" width="16" height="3" rx="1.5" fill="#FFFFFF" fill-opacity="0.5"/>
<circle cx="292" cy="130" r="13" fill="#FFFFFF"/>
<path d="M286 130 l4 4 l8 -9" fill="none" stroke="#1E8A5A" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M24 84 h26 l10 10 v34 a4 4 0 0 1 -4 4 h-32 a4 4 0 0 1 -4 -4 v-40 a4 4 0 0 1 4 -4z" fill="#D9B36A"/>
<g fill="none" stroke="#A9843F" stroke-width="1.2"><path d="M20 100 H60 M20 116 H60 M32 84 V132 M46 94 V132"/></g>
${_bar(id: "moh", top: "#198A59", bottom: "#116641", icon: _icons.phone, value: "{{mobilenumber}}", tileOpacity: "0.14", tileStrokeOpacity: "0.28")}
${_issuer("#D3F0E1")}'''),

  "pbdf.pbdf.iban": _svg('''
<defs>
<linearGradient id="ibb" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#23313E"/><stop offset="0.55" stop-color="#2E4254"/><stop offset="1" stop-color="#1E2A35"/></linearGradient>
<linearGradient id="ibc" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#EBCB86"/><stop offset="1" stop-color="#C79C4D"/></linearGradient>
</defs>
<rect width="358" height="226" fill="url(#ibb)"/>
<path d="M176 64 L276 64 L170 226 L70 226 Z" fill="#FFFFFF" fill-opacity="0.045"/>
<path d="M300 64 L336 64 L230 226 L194 226 Z" fill="#FFFFFF" fill-opacity="0.035"/>
${_bar(id: "ibh", top: "#1A242E", bottom: "#0D141A", icon: _icons.bank, value: "{{fullname}}", edgeOpacity: "0.12", tileOpacity: "0.1", tileStrokeOpacity: "0.22", labelColor: "#9FB3C8", labelOpacity: "1")}
<rect x="20" y="82" width="46" height="36" rx="8" fill="url(#ibc)"/>
<g fill="none" stroke="#A9843F" stroke-width="1.2"><path d="M20 94 H34 M52 94 H66 M20 106 H34 M52 106 H66 M34 82 V118 M52 82 V118"/><rect x="34" y="90" width="18" height="20" rx="3"/></g>
<g fill="none" stroke="#9FB3C8" stroke-width="2.2" stroke-linecap="round"><path d="M80 91 A13 13 0 0 1 80 109"/><path d="M87 86 A20 20 0 0 1 87 114"/><path d="M94 81 A27 27 0 0 1 94 119"/></g>
<text x="20" y="163.2" font-family="$_display" font-size="18" font-weight="600" letter-spacing="1.5" fill="#000000" fill-opacity="0.45">{{iban}}</text>
<text x="20" y="162" font-family="$_display" font-size="18" font-weight="600" letter-spacing="1.5" fill="#EEF2F6">{{iban}}</text>
<text x="20" y="188" font-family="$_body" font-size="10.5" fill="#9FB3C8">{{label.bic}}</text>
<text x="52" y="188" font-family="$_body" font-size="13" font-weight="700" fill="#FFFFFF">{{bic}}</text>
${_issuer("#9FB3C8")}'''),
};
