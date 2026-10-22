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

  static BoxShadow _shadow(YiviPalette palette) => BoxShadow(
    color: palette.isDark ? const Color(0x40000000) : const Color(0x17000000),
    blurRadius: 6,
    offset: const Offset(0, 1),
  );

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    // The fill is a Material, so rows that paint ink (ListTile, InkWell)
    // show their splashes on it; the shadow sits on a box around it.
    final group = DecoratedBox(
      decoration: _GroupDecoration(shadow: _shadow(palette)),
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

/// [GlassGroup] for a long list in a [CustomScrollView]: the same group, but
/// its rows are built as they scroll into view. The group's fill and shadow
/// are drawn behind the rows ([DecoratedSliver]); each row is on a
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
          decoration: _GroupDecoration(
            color: palette.surface,
            shadow: GlassGroup._shadow(palette),
          ),
          sliver: SliverList.separated(
            itemCount: itemCount,
            // The first and last rows take the group's corners, so a
            // pressed row lights up inside the group, not square over it.
            itemBuilder: (context, i) => Material(
              type: MaterialType.transparency,
              shape: RoundedSuperellipseBorder(
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

/// A group's look: [color] in the group's rounded shape, over a soft
/// [shadow]. The shadow is a blurred rounded rectangle, which the renderer
/// draws directly; as a shape's shadow (a superellipse path) it was blurred
/// in a layer of its own, over the whole group, on every frame. Under a blur
/// of 6 the corners look the same.
class _GroupDecoration extends Decoration {
  final Color? color;
  final BoxShadow shadow;

  const _GroupDecoration({this.color, required this.shadow});

  static const _shape = RoundedSuperellipseBorder(
    borderRadius: GlassGroup.radius,
  );

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _GroupPainter(this);

  @override
  bool operator ==(Object other) =>
      other is _GroupDecoration &&
      other.color == color &&
      other.shadow == shadow;

  @override
  int get hashCode => Object.hash(color, shadow);
}

class _GroupPainter extends BoxPainter {
  final _GroupDecoration decoration;

  _GroupPainter(this.decoration);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final rect = offset & configuration.size!;
    final shadow = decoration.shadow;
    canvas.drawRRect(
      GlassGroup.radius.toRRect(
        rect.shift(shadow.offset).inflate(shadow.spreadRadius),
      ),
      shadow.toPaint(),
    );
    final color = decoration.color;
    if (color != null) {
      _GroupDecoration._shape.paintInterior(
        canvas,
        rect,
        Paint()..color = color,
      );
    }
  }
}
