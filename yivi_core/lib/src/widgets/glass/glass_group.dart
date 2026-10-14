import "package:material_ui/material_ui.dart";

import "../../theme/yivi_palette.dart";

/// A rounded group of rows on a surface, with thin dividers between them,
/// like the groups in Settings and More. An optional [header] sits above the
/// group, outside it.
class GlassGroup extends StatelessWidget {
  final List<Widget> children;

  /// Where the dividers start: 16 for plain rows, 68 for rows with an icon
  /// square in front.
  final double dividerIndent;

  final String? header;

  const GlassGroup({
    super.key,
    required this.children,
    this.dividerIndent = 16,
    this.header,
  });

  static const radius = BorderRadius.all(Radius.circular(24));

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    // The fill is a Material, so rows that paint ink (ListTile, InkWell)
    // show their splashes on it; the shadow sits on a box around it.
    final group = DecoratedBox(
      decoration: ShapeDecoration(
        shape: const RoundedSuperellipseBorder(borderRadius: radius),
        shadows: [
          BoxShadow(
            color: palette.isDark
                ? const Color(0x40000000)
                : const Color(0x17000000),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: palette.surface,
        shape: const RoundedSuperellipseBorder(borderRadius: radius),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: dividerIndent,
                  color: palette.divider,
                ),
            ],
          ],
        ),
      ),
    );
    if (header == null) return group;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
          child: Semantics(
            header: true,
            child: Text(header!, style: palette.display(16)),
          ),
        ),
        group,
      ],
    );
  }
}
