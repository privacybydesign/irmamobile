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

/// [GlassGroup] for a long list in a [CustomScrollView]: the same group, but
/// its rows are built as they scroll into view. The group's fill is drawn
/// behind the rows ([DecoratedSliver]); each row is on a
/// transparent [Material], so its ink shows on the fill.
class SliverGlassGroup extends StatelessWidget {
  final String? header;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double dividerIndent;

  const SliverGlassGroup({
    super.key,
    this.header,
    required this.itemCount,
    required this.itemBuilder,
    this.dividerIndent = 16,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final header = this.header;
    return SliverMainAxisGroup(
      slivers: [
        if (header != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
              child: Semantics(
                header: true,
                child: Text(header, style: palette.display(16)),
              ),
            ),
          ),
        DecoratedSliver(
          decoration: ShapeDecoration(
            color: palette.surface,
            shape: GlassGroup._shape(context),
          ),
          sliver: SliverList.separated(
            itemCount: itemCount,
            // The first and last rows take the group's corners, so a
            // pressed row lights up inside the group, not square over it.
            itemBuilder: (context, i) => Material(
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
            separatorBuilder: (_, _) => Divider(
              height: 1,
              thickness: 1,
              indent: dividerIndent,
              color: palette.divider,
            ),
          ),
        ),
      ],
    );
  }
}
