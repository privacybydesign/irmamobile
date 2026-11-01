import "package:material_ui/material_ui.dart";

import "../../theme/yivi_corners.dart";
import "../../theme/yivi_edges.dart";
import "../../theme/yivi_palette.dart";

/// A rounded group of rows on a surface, with thin dividers between them,
/// like the groups in Settings and More. Flat: its colour sets it off from
/// the page, an outline too with Increase Contrast ([YiviEdges.block]). An optional [header] sits above the
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

  static const radius = YiviCorners.cardRadius;

  static RoundedRectangleBorder _shape(BuildContext context) =>
      RoundedRectangleBorder(
        borderRadius: radius,
        side: YiviEdges.block(context),
      );

  /// The line between two rows.
  static Divider _divider(YiviPalette palette, double indent) =>
      Divider(height: 1, thickness: 1, indent: indent, color: palette.divider);

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    // The fill is a Material, so rows that paint ink (ListTile, InkWell)
    // show their splashes on it.
    final group = Material(
      color: palette.surface,
      shape: _shape(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) _divider(palette, dividerIndent),
          ],
        ],
      ),
    );
    if (header == null) return group;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [_GroupHeader(header!), group],
    );
  }
}

/// [GlassGroup] for a long list in a [CustomScrollView]: the same group, but
/// its rows are built as they scroll into view. The group's fill is drawn
/// behind the rows ([DecoratedSliver]); each row is on a
/// transparent [Material], so its ink shows on the fill.
class SliverGlassGroup extends StatelessWidget {
  final String? header;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double dividerIndent;

  /// A band from edge to edge instead of a rounded group (as the Activity
  /// tab's months): square, a hairline above and below it in light mode.
  /// For a list with no side padding; the header then keeps 16 from the
  /// edge.
  final bool fullWidth;

  const SliverGlassGroup({
    super.key,
    this.header,
    required this.itemCount,
    required this.itemBuilder,
    this.dividerIndent = 16,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final header = this.header;
    return SliverMainAxisGroup(
      slivers: [
        if (header != null)
          SliverToBoxAdapter(
            child: _GroupHeader(header, inset: fullWidth ? 16 : 4),
          ),
        DecoratedSliver(
          decoration: fullWidth
              ? BoxDecoration(
                  color: palette.surface,
                  border: palette.isDark
                      ? null
                      : Border.symmetric(
                          horizontal: BorderSide(color: palette.divider),
                        ),
                )
              : ShapeDecoration(
                  color: palette.surface,
                  shape: GlassGroup._shape(context),
                ),
          sliver: SliverList.separated(
            itemCount: itemCount,
            // The first and last rows take the group's corners, so a
            // pressed row lights up inside the group, not square over it.
            itemBuilder: (context, i) => fullWidth
                ? itemBuilder(context, i)
                : Material(
                    type: MaterialType.transparency,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: i == 0 ? GlassGroup.radius.topLeft : Radius.zero,
                        bottom: i == itemCount - 1
                            ? GlassGroup.radius.bottomLeft
                            : Radius.zero,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: itemBuilder(context, i),
                  ),
            separatorBuilder: (_, _) =>
                GlassGroup._divider(palette, dividerIndent),
          ),
        ),
      ],
    );
  }
}

/// The header above a group, outside it.
class _GroupHeader extends StatelessWidget {
  final String text;

  /// From the side of the group (or the screen, for a band).
  final double inset;

  const _GroupHeader(this.text, {this.inset = 4});

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(inset, 24, inset, 8),
    child: Semantics(
      header: true,
      child: Text(text, style: YiviPalette.of(context).display(16)),
    ),
  );
}
