import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:material_ui/material_ui.dart";

import "../theme/theme.dart";

const _svgNamespace = "http://www.w3.org/2000/svg";
const _buttonSize = 44.0;

/// The icons of the redesigned data tab and add data screen, drawn as on the
/// design boards. The shapes use `currentColor`, which [DataTabIcon] sets.
enum DataTabGlyph {
  arrowBack(
    '<path d="M20 12H5M11 5l-7 7 7 7" fill="none" stroke="currentColor" '
    'stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>',
  ),
  chevronRight(
    '<path d="M9 5l7 7-7 7" fill="none" stroke="currentColor" '
    'stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>',
  ),
  chevronDown(
    '<path d="M6 9l6 6 6-6" fill="none" stroke="currentColor" '
    'stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>',
  ),
  plusCircle(
    '<circle cx="12" cy="12" r="11" fill="currentColor"/>'
    '<path d="M12 7v10M7 12h10" stroke="#fff" stroke-width="2.4" '
    'stroke-linecap="round"/>',
  ),
  search(
    '<circle cx="10.5" cy="10.5" r="6.5" fill="none" stroke="currentColor" '
    'stroke-width="2"/>'
    '<path d="M15.5 15.5L21 21" stroke="currentColor" stroke-width="2" '
    'stroke-linecap="round"/>',
  ),
  star(
    '<path d="M12 3l2.7 5.6 6.1.9-4.4 4.3 1 6.1L12 17l-5.4 2.9 1-6.1-4.4-4.3 '
    '6.1-.9z" fill="currentColor"/>',
  );

  const DataTabGlyph(this._shapes);

  final String _shapes;

  String get _svg =>
      '<svg xmlns="$_svgNamespace" viewBox="0 0 24 24">$_shapes</svg>';
}

class DataTabIcon extends StatelessWidget {
  const DataTabIcon(
    this.glyph, {
    super.key,
    required this.size,
    required this.color,
  });

  final DataTabGlyph glyph;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      glyph._svg,
      width: size,
      height: size,
      theme: SvgTheme(currentColor: color),
    );
  }
}

class DataTabIconButton extends StatelessWidget {
  const DataTabIconButton(
    this.glyph, {
    super.key,
    required this.iconSize,
    required this.labelKey,
    required this.onTap,
  });

  final DataTabGlyph glyph;
  final double iconSize;
  final String labelKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Semantics(
      button: true,
      label: FlutterI18n.translate(context, labelKey),
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox.square(
          dimension: _buttonSize,
          child: Center(
            child: DataTabIcon(glyph, size: iconSize, color: theme.dark),
          ),
        ),
      ),
    );
  }
}
