# irma-icons

The IrmaIcons Dart class and .ttf font are generated from SVG files by [icon_font_generator](https://pub.dev/packages/icon_font_generator).

The icon_font_generator tool must be installed by developers who wish to modify the IrmaIcon font.

## Install

```bash
pub global activate icon_font_generator
```

## Usage

Add or remove .svg files to the `fonts/irma-icons/icons` folder. Make sure the .svg file names are snake_cased. Don't use dashes or capitals in the filename.

Make sure SVG files have a height of 512pt, and apropriate width (in most cases also 512pt). This is needed so that the tool can correctly map the SVG to glyph size.

Re-generate the font by executing the following command in the project root:

```bash
icon_font_generator \
    --from=fonts/irma-icons/icons \
    --class-name=IrmaIcons \
    --out-font=fonts/irma-icons/IrmaIcons.ttf \
    --out-flutter=lib/src/theme/irma-icons.dart
```
