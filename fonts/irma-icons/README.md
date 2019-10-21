# irma-icons

The IrmaIcons Dart class and .ttf font are generated from SVG files by [icon_font_generator](https://pub.dev/packages/icon_font_generator).

`icon_font_generator` must be installed by developers who wish to modify the IrmaIcon font.

## Install dependencies

```bash
pub global activate icon_font_generator
```

## Usage

Add or remove .svg files to the `fonts/irma-icons/icons` folder. Make sure the .svg file names are lower_snake_cased. Don't use dashes or capitals in the filename.

Make sure SVG files have a height of 512pt, and apropriate width (in most cases also 512pt). This is needed so that the tool can correctly map the SVG to glyph size.

Manually pass over the new svg files to fix their code.

- Move the glyph `<path>` object from the `<def>` block into the first `<g>` and set the `<g>`'s fill to `#000`.
- Remove id on the `<path>`
- Remove the `<def>` block
- Remove the `<mask>`, the `<use>` and the `<g><rect/></g>` (enourmous background thing);

```svg
<mask id="b" fill="#fff">
    <use xlink:href="#a"/>
</mask>
<use fill="#000" fill-rule="nonzero" xlink:href="#a"/>
<g fill="#15222E" mask="url(#b)">
    <rect width="1948.913" height="1948.913" rx="1.667" transform="translate(-725.333 -725.333)"/>
</g>
```

Before:

```svg
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="416" height="416" viewBox="0 0 416 416">
  <defs>
    <path id="add-a" d="M213.333333,5.33333333 C222.169889,5.33333333 229.333333,12.4967773 229.333333,21.3333333 L229.333333,21.3333333 L229.333333,197.333333 L405.333333,197.333333 C414.064692,197.333333 421.162538,204.327234 421.330297,213.018463 L421.333333,213.333333 C421.333333,222.169889 414.169889,229.333333 405.333333,229.333333 L405.333333,229.333333 L229.333333,229.333333 L229.333333,405.333333 C229.333333,414.064692 222.339432,421.162538 213.648204,421.330297 L213.333333,421.333333 C204.496777,421.333333 197.333333,414.169889 197.333333,405.333333 L197.333333,405.333333 L197.333333,229.333333 L21.3333333,229.333333 C12.6019744,229.333333 5.50412864,222.339432 5.33636975,213.648204 L5.33333333,213.333333 C5.33333333,204.496777 12.4967773,197.333333 21.3333333,197.333333 L21.3333333,197.333333 L197.333333,197.333333 L197.333333,21.3333333 C197.333333,12.6019744 204.327234,5.50412864 213.018463,5.33636975 Z"/>
  </defs>
  <g fill="none" fill-rule="evenodd" transform="translate(-5.333 -5.333)">
    <mask id="add-b" fill="#fff">
      <use xlink:href="#add-a"/>
    </mask>
    <use fill="#000" fill-rule="nonzero" xlink:href="#add-a"/>
    <g fill="#15222E" mask="url(#add-b)">
      <rect width="1948.913" height="1948.913" rx="1.667" transform="translate(-768 -768)"/>
    </g>
  </g>
</svg>
```

After:

```svg
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="416" height="416" viewBox="0 0 416 416">
  <g fill="#000" fill-rule="evenodd" transform="translate(-5.333 -5.333)">
    <path d="M213.333333,5.33333333 C222.169889,5.33333333 229.333333,12.4967773 229.333333,21.3333333 L229.333333,21.3333333 L229.333333,197.333333 L405.333333,197.333333 C414.064692,197.333333 421.162538,204.327234 421.330297,213.018463 L421.333333,213.333333 C421.333333,222.169889 414.169889,229.333333 405.333333,229.333333 L405.333333,229.333333 L229.333333,229.333333 L229.333333,405.333333 C229.333333,414.064692 222.339432,421.162538 213.648204,421.330297 L213.333333,421.333333 C204.496777,421.333333 197.333333,414.169889 197.333333,405.333333 L197.333333,405.333333 L197.333333,229.333333 L21.3333333,229.333333 C12.6019744,229.333333 5.50412864,222.339432 5.33636975,213.648204 L5.33333333,213.333333 C5.33333333,204.496777 12.4967773,197.333333 21.3333333,197.333333 L21.3333333,197.333333 L197.333333,197.333333 L197.333333,21.3333333 C197.333333,12.6019744 204.327234,5.50412864 213.018463,5.33636975 Z"/>
  </g>
</svg>
```


When all SVG's look good, re-generate the font by executing the following command in the project root:

```bash
icon_font_generator \
    --height 512 \
    --normalize \
    --from=fonts/irma-icons/icons \
    --class-name=IrmaIcons \
    --out-font=fonts/irma-icons/IrmaIcons.ttf \
    --out-flutter=lib/src/theme/irma-icons.dart
```
