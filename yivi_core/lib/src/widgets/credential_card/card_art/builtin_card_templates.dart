import "../../../../package_name.dart";
import "../../../models/schemaless/schemaless_events.dart" as schemaless;

/// Card templates Yivi ships for its own credentials (the PbDF scheme), in
/// the same SVG + `{{placeholder}}` format issuers use for SD-JWT VC
/// `svg_templates`. The top 64 points of each card hold a pictogram, the
/// credential's name and its main value, with a small illustration on the
/// right: that is what a card shows in the stack, so the type and the value
/// that tells cards apart read at a glance. The card is one colour from the
/// top down, with no band behind the header: in the stack the corners of the
/// next card show the strip just under it, and a different colour there
/// looked out of place. Below the header the card is drawn as an object of
/// its type (a map, a passport page, an envelope, …).
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

String _svg(String body) =>
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 358 226" width="358" height="226">$body</svg>';

// Drawn on the "Yivi Built-in Card Templates" design canvas (round 4).
final _templates = <String, String>{
  "pbdf.gemeente.personalData": _svg(
    '''
<defs><linearGradient id="pd_p4b" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#22507E"></stop><stop offset="1" stop-color="#15375C"></stop></linearGradient></defs>
<rect width="358" height="226" fill="url(#pd_p4b)"></rect>
<g fill="none" stroke="#FFFFFF" stroke-opacity="0.13" stroke-width="0.8"><path d="M200 14 q6.0 -4 12.0 0 t12.0 0 q6.0 -4 12.0 0 t12.0 0 q6.0 -4 12.0 0 t12.0 0 q6.0 -4 12.0 0 t12.0 0 q6.0 -4 12.0 0 t12.0 0 q6.0 -4 12.0 0 t12.0 0 q6.0 -4 12.0 0 t12.0 0"></path><path d="M200 20 q6.0 -4 12.0 0 t12.0 0 q6.0 -4 12.0 0 t12.0 0 q6.0 -4 12.0 0 t12.0 0 q6.0 -4 12.0 0 t12.0 0 q6.0 -4 12.0 0 t12.0 0 q6.0 -4 12.0 0 t12.0 0 q6.0 -4 12.0 0 t12.0 0"></path><path d="M200 26 q6.0 -4 12.0 0 t12.0 0 q6.0 -4 12.0 0 t12.0 0 q6.0 -4 12.0 0 t12.0 0 q6.0 -4 12.0 0 t12.0 0 q6.0 -4 12.0 0 t12.0 0 q6.0 -4 12.0 0 t12.0 0 q6.0 -4 12.0 0 t12.0 0"></path><path d="M200 32 q6.0 -4 12.0 0 t12.0 0 q6.0 -4 12.0 0 t12.0 0 q6.0 -4 12.0 0 t12.0 0 q6.0 -4 12.0 0 t12.0 0 q6.0 -4 12.0 0 t12.0 0 q6.0 -4 12.0 0 t12.0 0 q6.0 -4 12.0 0 t12.0 0"></path><path d="M200 38 q6.0 -4 12.0 0 t12.0 0 q6.0 -4 12.0 0 t12.0 0 q6.0 -4 12.0 0 t12.0 0 q6.0 -4 12.0 0 t12.0 0 q6.0 -4 12.0 0 t12.0 0 q6.0 -4 12.0 0 t12.0 0 q6.0 -4 12.0 0 t12.0 0"></path><path d="M200 44 q6.0 -4 12.0 0 t12.0 0 q6.0 -4 12.0 0 t12.0 0 q6.0 -4 12.0 0 t12.0 0 q6.0 -4 12.0 0 t12.0 0 q6.0 -4 12.0 0 t12.0 0 q6.0 -4 12.0 0 t12.0 0 q6.0 -4 12.0 0 t12.0 0"></path><path d="M200 50 q6.0 -4 12.0 0 t12.0 0 q6.0 -4 12.0 0 t12.0 0 q6.0 -4 12.0 0 t12.0 0 q6.0 -4 12.0 0 t12.0 0 q6.0 -4 12.0 0 t12.0 0 q6.0 -4 12.0 0 t12.0 0 q6.0 -4 12.0 0 t12.0 0"></path></g><g transform="translate(318 32)" fill="none" stroke="#FFFFFF" stroke-opacity="0.35" stroke-width="1"><circle r="14"></circle><circle r="10" stroke-dasharray="1.5 2"></circle><path d="M-5 4 l5 -10 l5 10 z M-6 -2 h12"></path></g>
<g transform="translate(300 160)" fill="none" stroke="#FFFFFF" stroke-opacity="0.09" stroke-width="1">
<ellipse rx="62" ry="16"></ellipse><ellipse rx="62" ry="16" transform="rotate(15)"></ellipse><ellipse rx="62" ry="16" transform="rotate(30)"></ellipse><ellipse rx="62" ry="16" transform="rotate(45)"></ellipse><ellipse rx="62" ry="16" transform="rotate(60)"></ellipse><ellipse rx="62" ry="16" transform="rotate(75)"></ellipse><ellipse rx="62" ry="16" transform="rotate(90)"></ellipse><ellipse rx="62" ry="16" transform="rotate(105)"></ellipse><ellipse rx="62" ry="16" transform="rotate(120)"></ellipse><ellipse rx="62" ry="16" transform="rotate(135)"></ellipse><ellipse rx="62" ry="16" transform="rotate(150)"></ellipse><ellipse rx="62" ry="16" transform="rotate(165)"></ellipse>
<circle r="28"></circle><circle r="46"></circle><circle r="62" stroke-dasharray="2 3"></circle>
</g>
<circle cx="300" cy="160" r="12" fill="#FFFFFF" fill-opacity="0.07"></circle>
<g fill="none" stroke="#FFFFFF" stroke-width="0.8"><path d="M0 194 C30 186 60 202 90 194 S150 186 180 194 S240 202 270 194 S330 186 358 194" stroke-opacity="0.14"></path><path d="M0 199 C30 191 60 207 90 199 S150 191 180 199 S240 207 270 199 S330 191 358 199" stroke-opacity="0.08"></path></g>
<rect x="18.5" y="16.5" width="31" height="31" rx="10" fill="#FFFFFF" fill-opacity="0.13" stroke="#FFFFFF" stroke-opacity="0.26"></rect>
<g transform="translate(22 20)" fill="none" stroke="#FFFFFF" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M12 4a4 4 0 1 1 0 8a4 4 0 1 1 0-8z M4.5 21c0-4.2 3.4-6.8 7.5-6.8s7.5 2.6 7.5 6.8"></path></g>
<text font-family="$_body" x="62" y="28" font-size="10.5" font-weight="700" letter-spacing="0.4" fill="#FFFFFF" fill-opacity="0.72">{{yivi.name}}</text>
<text x="62" y="48" font-family="$_display" font-size="17" font-weight="700" fill="#FFFFFF">{{fullname}}</text>
<g font-size="10.5" fill="#A9C3E0"><text font-family="$_body" x="20" y="96">{{label.dateofbirth}}</text><text font-family="$_body" x="140" y="96">{{label.cityofbirth}}</text><text font-family="$_body" x="20" y="138">{{label.nationality}}</text><text font-family="$_body" x="140" y="138">{{label.gender}}</text></g>
<g font-size="15" font-weight="600" fill="#FFFFFF"><text font-family="$_body" x="20" y="114">{{dateofbirth}}</text><text font-family="$_body" x="140" y="114">{{cityofbirth}}</text><text font-family="$_body" x="20" y="156">{{nationality}}</text><text font-family="$_body" x="140" y="156">{{gender}}</text></g>
<text font-family="$_body" x="20" y="216" font-size="10" fill="#A9C3E0">{{yivi.issuer}}</text>''',
  ),

  "pbdf.gemeente.address": _svg(
    '''
<defs>
<linearGradient id="ad_a4b" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#CB6134"></stop><stop offset="1" stop-color="#A6451E"></stop></linearGradient>
<clipPath id="ad_a4m"><rect x="190" y="96" width="148" height="106" rx="16"></rect></clipPath>
</defs>
<rect width="358" height="226" fill="url(#ad_a4b)"></rect>
<g fill="#FFFFFF" fill-opacity="0.16"><path d="M226 58 V44 l7 -7 l7 7 V58 z M242 58 V36 l9 -10 l9 10 V58 z M262 58 V42 l6 -6 l6 6 V58 z M276 58 V30 l10 -12 l10 12 V58 z M298 58 V40 l8 -8 l8 8 V58 z M316 58 V46 l6 -6 l6 6 V58 z"></path></g><g fill="#FFFFFF" fill-opacity="0.28"><rect x="249" y="40" width="4" height="5" rx="1"></rect><rect x="283" y="34" width="4" height="5" rx="1"></rect><rect x="283" y="44" width="4" height="5" rx="1"></rect><rect x="304" y="46" width="4" height="5" rx="1"></rect></g><path d="M220 58.5 H334" stroke="#FFFFFF" stroke-opacity="0.3" stroke-width="1"></path>
<g clip-path="url(#ad_a4m)">
<rect x="190" y="96" width="148" height="106" fill="#FBEFE2"></rect>
<rect x="282" y="96" width="56" height="40" rx="6" fill="#D5E5BF"></rect>
<g fill="#F1DCC6"><rect x="194" y="100" width="38" height="24" rx="5"></rect><rect x="240" y="100" width="36" height="24" rx="5"></rect><rect x="194" y="132" width="38" height="30" rx="5"></rect><rect x="194" y="170" width="54" height="28" rx="5"></rect><rect x="298" y="144" width="40" height="54" rx="5"></rect></g>
<path d="M230 206 C 240 176, 270 168, 288 142 S 316 108, 342 98" fill="none" stroke="#A9D3EE" stroke-width="11" stroke-linecap="round"></path>
<g stroke="#FFFFFF" stroke-width="5" stroke-linecap="round" fill="none"><path d="M190 128 H338"></path><path d="M236 96 V202"></path><path d="M280 96 V140"></path><path d="M190 166 H292"></path></g>
<ellipse cx="258" cy="152" rx="9" ry="3" fill="#000000" fill-opacity="0.15"></ellipse>
<path d="M245 124 c0 -17 26 -17 26 0 c0 12 -13 27 -13 27 s-13 -15 -13 -27z" fill="#C2552D"></path>
<circle cx="258" cy="124" r="5" fill="#FFFFFF"></circle>
</g>
<rect x="190.5" y="96.5" width="147" height="105" rx="15.5" fill="none" stroke="#FFFFFF" stroke-opacity="0.35"></rect>
<rect x="18.5" y="16.5" width="31" height="31" rx="10" fill="#FFFFFF" fill-opacity="0.16" stroke="#FFFFFF" stroke-opacity="0.3"></rect>
<g transform="translate(22 20)" fill="none" stroke="#FFFFFF" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M4 11 12 4l8 7 M6 9.5V20h12V9.5 M10 20v-5h4v5"></path></g>
<text font-family="$_body" x="62" y="28" font-size="10.5" font-weight="700" letter-spacing="0.4" fill="#FFFFFF" fill-opacity="0.8">{{yivi.name}}</text>
<text x="62" y="48" font-family="$_display" font-size="17" font-weight="700" fill="#FFFFFF">{{street}} {{houseNumber}}</text>
<text x="20" y="108" font-family="$_display" font-size="18" font-weight="700" fill="#FFFFFF">{{zipcode}}</text>
<text x="20" y="132" font-family="$_display" font-size="18" font-weight="700" fill="#FFFFFF">{{city}}</text>
<text font-family="$_body" x="20" y="164" font-size="10.5" fill="#F8D2BD">{{label.municipality}}</text>
<text font-family="$_body" x="20" y="182" font-size="15" font-weight="600" fill="#FFFFFF">{{municipality}}</text>
<text font-family="$_body" x="20" y="216" font-size="10" fill="#F8D2BD">{{yivi.issuer}}</text>''',
  ),

  "pbdf.pbdf.passport": _svg(
    '''
<defs>
<linearGradient id="pp_pp4b" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6E1C30"></stop><stop offset="1" stop-color="#4E1222"></stop></linearGradient>
</defs>
<rect width="358" height="226" fill="url(#pp_pp4b)"></rect>
<g fill="none" stroke="#E2C07E" stroke-opacity="0.14" stroke-width="0.8"><path d="M170 18 q5.0 -3 10.0 0 t10.0 0 q5.0 -3 10.0 0 t10.0 0 q5.0 -3 10.0 0 t10.0 0 q5.0 -3 10.0 0 t10.0 0 q5.0 -3 10.0 0 t10.0 0 q5.0 -3 10.0 0 t10.0 0 q5.0 -3 10.0 0 t10.0 0"></path><path d="M170 26 q5.0 -3 10.0 0 t10.0 0 q5.0 -3 10.0 0 t10.0 0 q5.0 -3 10.0 0 t10.0 0 q5.0 -3 10.0 0 t10.0 0 q5.0 -3 10.0 0 t10.0 0 q5.0 -3 10.0 0 t10.0 0 q5.0 -3 10.0 0 t10.0 0"></path><path d="M170 34 q5.0 -3 10.0 0 t10.0 0 q5.0 -3 10.0 0 t10.0 0 q5.0 -3 10.0 0 t10.0 0 q5.0 -3 10.0 0 t10.0 0 q5.0 -3 10.0 0 t10.0 0 q5.0 -3 10.0 0 t10.0 0 q5.0 -3 10.0 0 t10.0 0"></path><path d="M170 42 q5.0 -3 10.0 0 t10.0 0 q5.0 -3 10.0 0 t10.0 0 q5.0 -3 10.0 0 t10.0 0 q5.0 -3 10.0 0 t10.0 0 q5.0 -3 10.0 0 t10.0 0 q5.0 -3 10.0 0 t10.0 0 q5.0 -3 10.0 0 t10.0 0"></path><path d="M170 50 q5.0 -3 10.0 0 t10.0 0 q5.0 -3 10.0 0 t10.0 0 q5.0 -3 10.0 0 t10.0 0 q5.0 -3 10.0 0 t10.0 0 q5.0 -3 10.0 0 t10.0 0 q5.0 -3 10.0 0 t10.0 0 q5.0 -3 10.0 0 t10.0 0"></path></g><g fill="#E2C07E" fill-opacity="0.75"><polygon points="318.0,14.8 318.5,16.3 320.1,16.3 318.9,17.3 319.3,18.8 318.0,17.9 316.7,18.8 317.1,17.3 315.9,16.3 317.5,16.3"></polygon><polygon points="325.5,16.8 326.0,18.3 327.6,18.3 326.4,19.3 326.8,20.8 325.5,19.9 324.2,20.8 324.6,19.3 323.4,18.3 325.0,18.3"></polygon><polygon points="331.0,22.3 331.5,23.8 333.1,23.8 331.9,24.8 332.3,26.3 331.0,25.4 329.7,26.3 330.1,24.8 328.9,23.8 330.4,23.8"></polygon><polygon points="333.0,29.8 333.5,31.3 335.1,31.3 333.9,32.3 334.3,33.8 333.0,32.9 331.7,33.8 332.1,32.3 330.9,31.3 332.5,31.3"></polygon><polygon points="331.0,37.3 331.5,38.8 333.1,38.8 331.9,39.8 332.3,41.3 331.0,40.4 329.7,41.3 330.1,39.8 328.9,38.8 330.4,38.8"></polygon><polygon points="325.5,42.8 326.0,44.2 327.6,44.3 326.4,45.3 326.8,46.8 325.5,45.9 324.2,46.8 324.6,45.3 323.4,44.3 325.0,44.2"></polygon><polygon points="318.0,44.8 318.5,46.3 320.1,46.3 318.9,47.3 319.3,48.8 318.0,47.9 316.7,48.8 317.1,47.3 315.9,46.3 317.5,46.3"></polygon><polygon points="310.5,42.8 311.0,44.2 312.6,44.3 311.4,45.3 311.8,46.8 310.5,45.9 309.2,46.8 309.6,45.3 308.4,44.3 310.0,44.2"></polygon><polygon points="305.0,37.3 305.6,38.8 307.1,38.8 305.9,39.8 306.3,41.3 305.0,40.4 303.7,41.3 304.1,39.8 302.9,38.8 304.5,38.8"></polygon><polygon points="303.0,29.8 303.5,31.3 305.1,31.3 303.9,32.3 304.3,33.8 303.0,32.9 301.7,33.8 302.1,32.3 300.9,31.3 302.5,31.3"></polygon><polygon points="305.0,22.3 305.6,23.8 307.1,23.8 305.9,24.8 306.3,26.3 305.0,25.4 303.7,26.3 304.1,24.8 302.9,23.8 304.5,23.8"></polygon><polygon points="310.5,16.8 311.0,18.3 312.6,18.3 311.4,19.3 311.8,20.8 310.5,19.9 309.2,20.8 309.6,19.3 308.4,18.3 310.0,18.3"></polygon></g>
<g fill="none" stroke="#D9B36A" stroke-width="0.9" stroke-opacity="0.16"><path d="M-10 112 Q179 92 368 112"></path><path d="M-10 124 Q179 104 368 124"></path><path d="M-10 136 Q179 116 368 136"></path><path d="M-10 148 Q179 128 368 148"></path></g>
<g fill="none" stroke="#D9B36A" stroke-width="1.6" stroke-opacity="0.9"><circle cx="294" cy="124" r="34"></circle><ellipse cx="294" cy="124" rx="13" ry="34"></ellipse><ellipse cx="294" cy="124" rx="25" ry="34"></ellipse><path d="M260 124 H328 M264 107 H324 M264 141 H324"></path></g>
<circle cx="294" cy="124" r="42" fill="none" stroke="#D9B36A" stroke-opacity="0.35" stroke-dasharray="1.5 3"></circle>
<rect x="20" y="86" width="56" height="72" rx="9" fill="#F3E7D3"></rect>
<g fill="#CDB48E"><circle cx="48" cy="112" r="12"></circle><path d="M29 158 C29 139 39 132 48 132 C57 132 67 139 67 158 Z"></path></g>
<defs><clipPath id="pp_photo"><rect x="20" y="86" width="56" height="72" rx="9"/></clipPath></defs><image href="{{photo}}" x="20" y="86" width="56" height="72" preserveAspectRatio="xMidYMid slice" clip-path="url(#pp_photo)"/>
<rect x="20" y="86" width="56" height="72" rx="9" fill="none" stroke="#D9B36A" stroke-width="1.5"></rect>
<g font-size="10.5" fill="#E2C07E"><text font-family="$_body" x="92" y="98">{{label.documentNumber}}</text><text font-family="$_body" x="92" y="136">{{label.dateOfExpiry}}</text></g>
<g font-size="15" font-weight="600" fill="#FFFFFF"><text font-family="$_body" x="92" y="116">{{documentNumber}}</text><text font-family="$_body" x="92" y="154">{{dateOfExpiry}}</text></g>
<rect x="0" y="174" width="358" height="52" fill="#000000" fill-opacity="0.24"></rect>
<g font-size="10.5" letter-spacing="1.3" fill="#EADBB8" fill-opacity="0.9"><text font-family="$_body" x="20" y="195">P&lt;{{country}}&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;</text><text font-family="$_body" x="20" y="212">{{documentNumber}}&lt;{{country}}&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;</text></g>
<rect x="18.5" y="16.5" width="31" height="31" rx="10" fill="#D9B36A" fill-opacity="0.16" stroke="#D9B36A" stroke-opacity="0.5"></rect>
<g transform="translate(22 20)" fill="none" stroke="#E2C07E" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M7 2.5h10a2 2 0 0 1 2 2v15a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2v-15a2 2 0 0 1 2-2z M12 7a3 3 0 1 1 0 6a3 3 0 1 1 0-6z M9 17h6"></path></g>
<text font-family="$_body" x="62" y="28" font-size="10.5" font-weight="700" letter-spacing="0.4" fill="#E2C07E">{{yivi.name}}</text>
<text x="62" y="48" font-family="$_display" font-size="17" font-weight="700" fill="#FFFFFF">{{firstName}} {{lastName}}</text>''',
  ),

  "pbdf.pbdf.drivinglicence": _svg(
    '''
<defs>
<linearGradient id="dl_dl4b" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#B53A66"></stop><stop offset="1" stop-color="#912449"></stop></linearGradient>
</defs>
<rect width="358" height="226" fill="url(#dl_dl4b)"></rect>
<g fill="none" stroke-linecap="round"><path d="M214 60 C250 52, 268 18, 340 10" stroke="#FFFFFF" stroke-opacity="0.14" stroke-width="16"></path><path d="M214 60 C250 52, 268 18, 340 10" stroke="#FFFFFF" stroke-opacity="0.5" stroke-width="1.4" stroke-dasharray="5 6"></path></g><g transform="translate(318 40)" fill="none" stroke="#FFFFFF" stroke-opacity="0.4" stroke-width="1.6"><circle r="9"></circle><circle r="2.2"></circle><path d="M-9 0 H-2.2 M2.2 0 H9 M0 2.2 V9"></path></g>
<path d="M150 252 C 210 184, 254 164, 384 132" fill="none" stroke="#FFFFFF" stroke-opacity="0.13" stroke-width="46" stroke-linecap="round"></path>
<path d="M150 252 C 210 184, 254 164, 384 132" fill="none" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="2.5" stroke-dasharray="12 10"></path>
<g fill="none" stroke="#FFFFFF" stroke-opacity="0.12" stroke-width="0.9"><path d="M0 190 C50 174 100 210 150 190"></path><path d="M0 198 C50 182 100 218 150 198"></path></g>
<rect x="20" y="86" width="56" height="72" rx="9" fill="#FFFFFF"></rect>
<g fill="#E9B7C8"><circle cx="48" cy="112" r="12"></circle><path d="M29 158 C29 139 39 132 48 132 C57 132 67 139 67 158 Z"></path></g>
<defs><clipPath id="dl_photo"><rect x="20" y="86" width="56" height="72" rx="9"/></clipPath></defs><image href="{{photo}}" x="20" y="86" width="56" height="72" preserveAspectRatio="xMidYMid slice" clip-path="url(#dl_photo)"/>
<rect x="20" y="86" width="56" height="72" rx="9" fill="none" stroke="#FFFFFF" stroke-opacity="0.7" stroke-width="1.5"></rect>
<g font-size="10.5" fill="#F8CFDD"><text font-family="$_body" x="92" y="98">{{label.documentNumber}}</text><text font-family="$_body" x="92" y="136">{{label.dateOfExpiry}}</text></g>
<g font-size="15" font-weight="600" fill="#FFFFFF"><text font-family="$_body" x="92" y="116">{{documentNumber}}</text><text font-family="$_body" x="92" y="154">{{dateOfExpiry}}</text></g>
<text font-family="$_body" x="20" y="216" font-size="10" fill="#F8CFDD">{{yivi.issuer}}</text>
<rect x="18.5" y="16.5" width="31" height="31" rx="10" fill="#FFFFFF" fill-opacity="0.16" stroke="#FFFFFF" stroke-opacity="0.3"></rect>
<g transform="translate(22 20)" fill="none" stroke="#FFFFFF" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3a9 9 0 1 1 0 18a9 9 0 1 1 0-18z M12 9.5a2.5 2.5 0 1 1 0 5a2.5 2.5 0 1 1 0-5z M3.5 11h6 M14.5 11h6 M12 14.5V21"></path></g>
<text font-family="$_body" x="62" y="28" font-size="10.5" font-weight="700" letter-spacing="0.4" fill="#FFFFFF" fill-opacity="0.8">{{yivi.name}}</text>
<text x="62" y="48" font-family="$_display" font-size="17" font-weight="700" fill="#FFFFFF">{{firstName}} {{lastName}}</text>''',
  ),

  "pbdf.pbdf.ageLimits": _svg(
    '''
<defs><linearGradient id="ag_ag4b" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#4A389F"></stop><stop offset="1" stop-color="#7B3EA3"></stop></linearGradient></defs>
<rect width="358" height="226" fill="url(#ag_ag4b)"></rect>
<g fill="#FFFFFF"><circle cx="236" cy="16" r="2" fill-opacity="0.35"></circle><circle cx="262" cy="46" r="2.5" fill-opacity="0.25"></circle><circle cx="300" cy="14" r="1.8" fill-opacity="0.4"></circle><circle cx="336" cy="50" r="2.2" fill-opacity="0.3"></circle><rect x="248" y="26" width="7" height="3" rx="1.5" transform="rotate(30 251 27)" fill-opacity="0.3"></rect><rect x="284" y="50" width="7" height="3" rx="1.5" transform="rotate(-25 287 51)" fill-opacity="0.3"></rect><rect x="326" y="22" width="7" height="3" rx="1.5" transform="rotate(60 329 23)" fill-opacity="0.35"></rect></g><g transform="translate(306 32)"><circle r="15" fill="#FFFFFF" fill-opacity="0.14"></circle><circle r="15" fill="none" stroke="#FFFFFF" stroke-opacity="0.45" stroke-width="1.2"></circle><text x="0" y="5" text-anchor="middle" font-family="$_display" font-size="13" font-weight="800" fill="#FFFFFF" fill-opacity="0.85">18+</text></g>
<circle cx="326" cy="214" r="88" fill="#FFFFFF" fill-opacity="0.05"></circle>
<circle cx="24" cy="244" r="70" fill="#FFFFFF" fill-opacity="0.05"></circle>
<path d="M44 140 H314" stroke="#FFFFFF" stroke-opacity="0.3" stroke-width="3" stroke-linecap="round"></path>
<g font-family="$_display" font-weight="800" text-anchor="middle">
<circle cx="44" cy="140" r="20" fill="#5A43AE" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="1.5"></circle><text x="44" y="145" font-size="13" fill="#FFFFFF">12</text>
<circle cx="111" cy="140" r="20" fill="#6141AD" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="1.5"></circle><text x="111" y="145" font-size="13" fill="#FFFFFF">16</text>
<circle cx="247" cy="140" r="20" fill="#7140A9" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="1.5"></circle><text x="247" y="145" font-size="13" fill="#FFFFFF">21</text>
<circle cx="314" cy="140" r="20" fill="#773FA6" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="1.5"></circle><text x="314" y="145" font-size="13" fill="#FFFFFF">65</text>
<circle cx="179" cy="140" r="26" fill="#FFFFFF"></circle><text x="179" y="146" font-size="16" fill="#3A2B86">18</text>
</g>
<g font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle"><text font-family="$_body" x="44" y="186">{{over12}}</text><text font-family="$_body" x="111" y="186">{{over16}}</text><text font-family="$_body" x="179" y="186">{{over18}}</text><text font-family="$_body" x="247" y="186">{{over21}}</text><text font-family="$_body" x="314" y="186">{{over65}}</text></g>
<text font-family="$_body" x="20" y="216" font-size="10" fill="#E3DCF7">{{yivi.issuer}}</text>
<rect x="18.5" y="16.5" width="31" height="31" rx="10" fill="#FFFFFF" fill-opacity="0.13" stroke="#FFFFFF" stroke-opacity="0.26"></rect>
<g transform="translate(22 20)" fill="none" stroke="#FFFFFF" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M4.5 8.5 7 7v10 M10.5 9.5a2 2 0 1 1 4 0a2 2 0 1 1-4 0z M10 14.5a2.5 2.5 0 1 1 5 0a2.5 2.5 0 1 1-5 0z M19 10v4 M17 12h4"></path></g>
<text font-family="$_body" x="62" y="28" font-size="10.5" font-weight="700" letter-spacing="0.4" fill="#FFFFFF" fill-opacity="0.72">{{yivi.name}}</text>
<text x="62" y="48" font-family="$_display" font-size="17" font-weight="700" fill="#FFFFFF">{{label.over18}}: {{over18}}</text>''',
  ),

  "pbdf.sidn-pbdf.email": _svg(
    '''
<defs><linearGradient id="em_em4b" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F3B640"></stop><stop offset="1" stop-color="#E29C1C"></stop></linearGradient></defs>
<rect width="358" height="226" fill="url(#em_em4b)"></rect>
<g fill="none" stroke="#7A4E00" stroke-opacity="0.3" stroke-width="1.2" stroke-dasharray="2 4" stroke-linecap="round"><path d="M214 54 C240 56, 262 40, 270 30 S292 14, 306 22"></path></g><g transform="translate(318 26) rotate(-12)"><path d="M-12 0 L12 -9 L4 11 L0 3 Z" fill="#FFFFFF" fill-opacity="0.85"></path><path d="M0 3 L12 -9" stroke="#C88A12" stroke-width="1" fill="none"></path></g><text x="240" y="24" font-family="$_display" font-size="14" font-weight="800" fill="#7A4E00" fill-opacity="0.18">@</text>
<g transform="translate(188 96)">
<rect width="150" height="100" rx="12" fill="#000000" fill-opacity="0.08" transform="translate(0 4)"></rect>
<rect width="150" height="100" rx="12" fill="#FFFDF7"></rect>
<path d="M2 96 L58 52 M148 96 L92 52" fill="none" stroke="#F1D9A6" stroke-width="1.5"></path>
<path d="M4 6 L75 58 L146 6" fill="#FDF1D6" stroke="#EBC57A" stroke-width="1.5" stroke-linejoin="round"></path>
<g transform="translate(104 14)"><rect width="34" height="40" rx="3" fill="#FFFFFF"></rect><rect width="34" height="40" rx="3" fill="none" stroke="#F3B640" stroke-width="3" stroke-dasharray="0.1 5" stroke-linecap="round"></rect><rect x="5" y="5" width="24" height="30" rx="2" fill="#FDF3DA"></rect><text x="17" y="27" text-anchor="middle" font-family="$_display" font-size="17" font-weight="800" fill="#B87A0E">@</text></g>
<g fill="none" stroke="#B87A0E" stroke-opacity="0.3" stroke-width="1.2"><path d="M62 22 c7 -4 12 4 19 0 s12 4 19 0"></path><path d="M62 29 c7 -4 12 4 19 0 s12 4 19 0"></path></g>
</g>
<text font-family="$_body" x="20" y="168" font-size="10.5" fill="#6E4600">{{label.domain}}</text>
<text font-family="$_body" x="20" y="186" font-size="15" font-weight="600" fill="#2E1E00">{{domain}}</text>
<text font-family="$_body" x="20" y="216" font-size="10" fill="#6E4600">{{yivi.issuer}}</text>
<rect x="18.5" y="16.5" width="31" height="31" rx="10" fill="#3A2500" fill-opacity="0.09" stroke="#3A2500" stroke-opacity="0.18"></rect>
<g transform="translate(22 20)" fill="none" stroke="#3A2500" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M5 5h14a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2z M3.5 6.5 12 13l8.5-6.5"></path></g>
<text font-family="$_body" x="62" y="28" font-size="10.5" font-weight="700" letter-spacing="0.4" fill="#3A2500" fill-opacity="0.7">{{yivi.name}}</text>
<text x="62" y="48" font-family="$_display" font-size="17" font-weight="700" fill="#2E1E00">{{email}}</text>''',
  ),

  "pbdf.sidn-pbdf.mobilenumber": _svg(
    '''
<defs><linearGradient id="mo_mo4b" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#1E8B5B"></stop><stop offset="1" stop-color="#136843"></stop></linearGradient></defs>
<rect width="358" height="226" fill="url(#mo_mo4b)"></rect>
<g fill="#FFFFFF" fill-opacity="0.07"><circle cx="220" cy="12" r="1.4"></circle><circle cx="220" cy="22" r="1.4"></circle><circle cx="220" cy="32" r="1.4"></circle><circle cx="220" cy="42" r="1.4"></circle><circle cx="220" cy="52" r="1.4"></circle><circle cx="230" cy="12" r="1.4"></circle><circle cx="230" cy="22" r="1.4"></circle><circle cx="230" cy="32" r="1.4"></circle><circle cx="230" cy="42" r="1.4"></circle><circle cx="230" cy="52" r="1.4"></circle><circle cx="240" cy="12" r="1.4"></circle><circle cx="240" cy="22" r="1.4"></circle><circle cx="240" cy="32" r="1.4"></circle><circle cx="240" cy="42" r="1.4"></circle><circle cx="240" cy="52" r="1.4"></circle><circle cx="250" cy="12" r="1.4"></circle><circle cx="250" cy="22" r="1.4"></circle><circle cx="250" cy="32" r="1.4"></circle><circle cx="250" cy="42" r="1.4"></circle><circle cx="250" cy="52" r="1.4"></circle><circle cx="260" cy="12" r="1.4"></circle><circle cx="260" cy="22" r="1.4"></circle><circle cx="260" cy="32" r="1.4"></circle><circle cx="260" cy="42" r="1.4"></circle><circle cx="260" cy="52" r="1.4"></circle><circle cx="270" cy="12" r="1.4"></circle><circle cx="270" cy="22" r="1.4"></circle><circle cx="270" cy="32" r="1.4"></circle><circle cx="270" cy="42" r="1.4"></circle><circle cx="270" cy="52" r="1.4"></circle><circle cx="280" cy="12" r="1.4"></circle><circle cx="280" cy="22" r="1.4"></circle><circle cx="280" cy="32" r="1.4"></circle><circle cx="280" cy="42" r="1.4"></circle><circle cx="280" cy="52" r="1.4"></circle><circle cx="290" cy="12" r="1.4"></circle><circle cx="290" cy="22" r="1.4"></circle><circle cx="290" cy="32" r="1.4"></circle><circle cx="290" cy="42" r="1.4"></circle><circle cx="290" cy="52" r="1.4"></circle></g><g transform="translate(296 14)"><rect width="38" height="16" rx="8" fill="#FFFFFF" fill-opacity="0.22"></rect><g fill="#FFFFFF" fill-opacity="0.8"><circle cx="12" cy="8" r="1.8"></circle><circle cx="19" cy="8" r="1.8"></circle><circle cx="26" cy="8" r="1.8"></circle></g></g><g transform="translate(276 36)"><rect width="30" height="14" rx="7" fill="#FFFFFF" fill-opacity="0.12"></rect></g>
<defs><linearGradient id="mo_mo4s" x1="0" y1="0" x2="0.4" y2="1"><stop offset="0" stop-color="#6FE0A9"></stop><stop offset="1" stop-color="#22A06A"></stop></linearGradient><linearGradient id="mo_mo4p" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#0B4A30"></stop><stop offset="1" stop-color="#06311F"></stop></linearGradient></defs>
<circle cx="268" cy="146" r="66" fill="#FFFFFF" fill-opacity="0.06"></circle>
<g fill="none" stroke="#B9F3D5" stroke-linecap="round" stroke-width="4"><path d="M306 120 a36 36 0 0 1 0 50" stroke-opacity="0.55"></path><path d="M318 108 a52 52 0 0 1 0 74" stroke-opacity="0.3"></path><path d="M230 120 a36 36 0 0 0 0 50" stroke-opacity="0.55"></path><path d="M218 108 a52 52 0 0 0 0 74" stroke-opacity="0.3"></path></g>
<rect x="240" y="98" width="56" height="98" rx="13" fill="url(#mo_mo4p)"></rect>
<rect x="240.75" y="98.75" width="54.5" height="96.5" rx="12.25" fill="none" stroke="#FFFFFF" stroke-opacity="0.5" stroke-width="1.5"></rect>
<rect x="245" y="103" width="46" height="88" rx="9" fill="url(#mo_mo4s)"></rect>
<rect x="260" y="106" width="16" height="4" rx="2" fill="#06311F"></rect>
<g fill="#FFFFFF"><rect x="250" y="120" width="2.4" height="3" rx="0.8"></rect><rect x="253.6" y="118" width="2.4" height="5" rx="0.8"></rect><rect x="257.2" y="116" width="2.4" height="7" rx="0.8"></rect></g>
<rect x="250" y="130" width="34" height="20" rx="7" fill="#FFFFFF"></rect>
<g fill="#1E8B5B"><circle cx="257" cy="140" r="2"></circle><circle cx="263.5" cy="140" r="2"></circle><circle cx="270" cy="140" r="2"></circle><circle cx="276.5" cy="140" r="2"></circle></g>
<rect x="250" y="156" width="22" height="4" rx="2" fill="#FFFFFF" fill-opacity="0.6"></rect>
<rect x="250" y="164" width="30" height="4" rx="2" fill="#FFFFFF" fill-opacity="0.4"></rect>
<circle cx="292" cy="180" r="12" fill="#FFFFFF"></circle>
<path d="M286.5 180 l3.6 3.6 l7.4 -8" fill="none" stroke="#1E8B5B" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"></path>
<path d="M24 96 h26 l10 10 v34 a4 4 0 0 1 -4 4 h-32 a4 4 0 0 1 -4 -4 v-40 a4 4 0 0 1 4 -4z" fill="#D9B36A"></path>
<g fill="none" stroke="#A9843F" stroke-width="1.2"><path d="M20 112 H60 M20 128 H60 M32 96 V144 M46 106 V144"></path></g>
<text font-family="$_body" x="20" y="216" font-size="10" fill="#D3F0E1">{{yivi.issuer}}</text>
<rect x="18.5" y="16.5" width="31" height="31" rx="10" fill="#FFFFFF" fill-opacity="0.14" stroke="#FFFFFF" stroke-opacity="0.28"></rect>
<g transform="translate(22 20)" fill="none" stroke="#FFFFFF" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M9.5 2.5h5a2.5 2.5 0 0 1 2.5 2.5v14a2.5 2.5 0 0 1-2.5 2.5h-5A2.5 2.5 0 0 1 7 19V5a2.5 2.5 0 0 1 2.5-2.5z M11 18.5h2"></path></g>
<text font-family="$_body" x="62" y="28" font-size="10.5" font-weight="700" letter-spacing="0.4" fill="#FFFFFF" fill-opacity="0.75">{{yivi.name}}</text>
<text x="62" y="48" font-family="$_display" font-size="17" font-weight="700" fill="#FFFFFF">{{mobilenumber}}</text>''',
  ),

  "pbdf.pbdf.iban": _svg(
    '''
<defs>
<linearGradient id="ib_ib4b" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#28374A"></stop><stop offset="1" stop-color="#1A242F"></stop></linearGradient>
<linearGradient id="ib_ib4c" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#EBCB86"></stop><stop offset="1" stop-color="#C79C4D"></stop></linearGradient>
</defs>
<rect width="358" height="226" fill="url(#ib_ib4b)"></rect>
<g fill="none" stroke="#9FB3C8" stroke-opacity="0.12" stroke-width="0.6"><path d="M190 12 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0"></path><path d="M190 17 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0"></path><path d="M190 22 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0"></path><path d="M190 27 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0"></path><path d="M190 32 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0"></path><path d="M190 37 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0"></path><path d="M190 42 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0"></path><path d="M190 47 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0"></path><path d="M190 52 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0 q2.5 -2 5.0 0 t5.0 0"></path></g><g transform="translate(312 32)"><circle r="15" fill="#9FB3C8" fill-opacity="0.16"></circle><circle r="15" fill="none" stroke="#9FB3C8" stroke-opacity="0.5" stroke-width="1"></circle><circle r="11" fill="none" stroke="#9FB3C8" stroke-opacity="0.35" stroke-width="0.8" stroke-dasharray="1 2"></circle><path d="M4 -5 a6 6 0 1 0 0 10 M-7 -1.5 h8 M-7 1.5 h8" fill="none" stroke="#C9D6E3" stroke-width="1.6" stroke-linecap="round"></path></g>
<path d="M196 102 L276 102 L196 226 L116 226 Z" fill="#FFFFFF" fill-opacity="0.04"></path>
<path d="M296 102 L330 102 L250 226 L216 226 Z" fill="#FFFFFF" fill-opacity="0.03"></path>
<g transform="translate(0 4)">
<rect x="20" y="92" width="46" height="36" rx="8" fill="url(#ib_ib4c)"></rect>
<g fill="none" stroke="#A9843F" stroke-width="1.2"><path d="M20 104 H34 M52 104 H66 M20 116 H34 M52 116 H66 M34 92 V128 M52 92 V128"></path><rect x="34" y="100" width="18" height="20" rx="3"></rect></g>
<g fill="none" stroke="#9FB3C8" stroke-width="2.2" stroke-linecap="round"><path d="M80 101 A13 13 0 0 1 80 119"></path><path d="M87 96 A20 20 0 0 1 87 124"></path><path d="M94 91 A27 27 0 0 1 94 129"></path></g>
</g>
<text x="20" y="167.2" font-family="$_display" font-size="18" font-weight="600" letter-spacing="1.5" fill="#000000" fill-opacity="0.45">{{iban}}</text>
<text x="20" y="166" font-family="$_display" font-size="18" font-weight="600" letter-spacing="1.5" fill="#EEF2F6">{{iban}}</text>
<text font-family="$_body" x="20" y="192" font-size="10.5" fill="#9FB3C8">{{label.bic}}</text>
<text font-family="$_body" x="44" y="192" font-size="13" font-weight="700" fill="#FFFFFF">{{bic}}</text>
<text font-family="$_body" x="20" y="216" font-size="10" fill="#9FB3C8">{{yivi.issuer}}</text>
<rect x="18.5" y="16.5" width="31" height="31" rx="10" fill="#FFFFFF" fill-opacity="0.1" stroke="#FFFFFF" stroke-opacity="0.22"></rect>
<g transform="translate(22 20)" fill="none" stroke="#FFFFFF" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M3 9.5 12 4l9 5.5 M5 10v8 M9.5 10v8 M14.5 10v8 M19 10v8 M3 20.5h18"></path></g>
<text font-family="$_body" x="62" y="28" font-size="10.5" font-weight="700" letter-spacing="0.4" fill="#9FB3C8">{{yivi.name}}</text>
<text x="62" y="48" font-family="$_display" font-size="17" font-weight="700" fill="#FFFFFF">{{fullname}}</text>''',
  ),
};
