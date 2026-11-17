part of "../yivi_credential_card_attribute_list.dart";

class _FlatRow extends StatelessWidget {
  final AttributeNode node;
  // The first row of the list: nothing is drawn above it.
  final bool isFirst;
  final _Ctx ctx;
  const _FlatRow({
    required this.node,
    required this.isFirst,
    required this.ctx,
  });

  // Space above and below a row in the document layout.
  static const _documentRowPadding = 6.0;

  @override
  Widget build(BuildContext context) {
    final pad = ctx.layout == .document ? _documentRowPadding : YiviSpace.x4;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: pad),
      child: _RowContent(node: node, isFirst: isFirst, ctx: ctx),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Row content — dispatches to the right inner widget based on node kind.
// ─────────────────────────────────────────────────────────────────────────────

class _RowContent extends StatelessWidget {
  final AttributeNode node;
  // The first row of the list: nothing is drawn above it.
  final bool isFirst;
  final _Ctx ctx;
  const _RowContent({
    required this.node,
    required this.isFirst,
    required this.ctx,
  });

  @override
  Widget build(BuildContext context) {
    return switch (node) {
      RowNode n => _LeafContent(node: n, ctx: ctx),
      AgeNode n => _AgeContent(node: n, layout: ctx.layout),
      PrimArrayNode n => _PrimArrayContent(node: n),
      // Only a header without values gets here (see rowDrawsBorder).
      GroupNode n => Text(n.label ?? "", style: attributeLabelStyle(context)),
      ItemNode() => const SizedBox.shrink(),
      AttributeGroupNode n => AttributeGroupScope(
        isFirst: isFirst,
        isDisclosure: ctx.disclosure,
        child: Builder(builder: n.group.build),
      ),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Leaf content — label on top, value below (no padding/border, container
// handles those).
// ─────────────────────────────────────────────────────────────────────────────

class _LeafContent extends StatelessWidget {
  final RowNode node;
  final _Ctx ctx;
  const _LeafContent({required this.node, required this.ctx});

  CredentialCardLayout get layout => ctx.layout;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final attribute = node.attribute;
    final found = node.found;
    final label = attribute.effectiveDisplayName;

    final column = Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        if (found == null && label == ctx.hideLabel)
          const SizedBox.shrink()
        else if (found == null)
          Text(label, style: attributeLabelStyle(context, layout: layout))
        else
          Text.rich(
            searchMarkSpan(
              label,
              findWordPrefix(
                label,
                foldQuery(found.query),
                ignoreHyphens: true,
              ),
              YiviPalette.of(context),
            ),
            style: attributeLabelStyle(context, layout: layout),
          ),
        _buildValue(context, theme),
      ],
    );
    return found == null ? column : _FoundRow(key: found.key, child: column);
  }

  Color _valueColor(
    BuildContext context,
    AttributeValue? val,
    IrmaThemeData theme,
  ) {
    if (node.mismatch) return YiviPalette.of(context).danger;
    if (node.match) return YiviPalette.of(context).successText;
    if (!node.hasCompareTo) return AttributeColors.of(context).value;
    return attributeValuesEqual(val, node.compareToValue)
        ? YiviPalette.of(context).successText
        : YiviPalette.of(context).danger;
  }

  Widget _buildValue(BuildContext context, IrmaThemeData theme) {
    final val = node.attribute.value;
    if (val == null) return const SizedBox.shrink();
    if (isImageAttribute(node.attribute)) return _tappableImage();
    final text = formatAttributeValue(context, val);
    final style = attributeValueStyle(
      context,
      _valueColor(context, val, theme),
      layout: layout,
    );
    final found = node.found;
    final tag = node.match
        ? ctx.matchedTag
        : node.mismatch
        ? ctx.mismatchedTag
        : null;
    if (found == null && tag != null) {
      return Wrap(
        spacing: YiviSpace.x8,
        runSpacing: YiviSpace.x4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(text, style: style),
          ValueTag(
            key: Key(node.match ? "value_tag_match" : "value_tag_mismatch"),
            text: tag,
            tone: node.match ? ValueTagTone.match : ValueTagTone.mismatch,
          ),
        ],
      );
    }
    // Plain text unless a search found this row: readers of the list (and
    // tests) look for its values as plain Text.
    if (found == null) return Text(text, style: style);
    return Text.rich(
      searchMarkSpan(
        text,
        findWordPrefix(text, foldQuery(found.query)),
        YiviPalette.of(context),
      ),
      style: style,
    );
  }

  Widget _tappableImage() {
    final attribute = node.attribute;
    final value = attribute.value;
    final bytes = decodeAttributeImage(value);
    if (bytes == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: YiviSpace.x4),
      // An SVG (an Open Badge's picture) is drawn like a logo; only a bitmap
      // opens full screen.
      child: isSvgImage(bytes, mimeType: value?.mimeType)
          ? ConstrainedBox(
              constraints: BoxConstraints.loose(AttributePhoto.thumbnail),
              child: Base64Image(
                base64: (value?.imagePath ?? value?.base64Image ?? "").trim(),
                mimeType: value?.mimeType,
              ),
            )
          : AttributePhoto(bytes: bytes, title: attribute.effectiveDisplayName),
    );
  }
}

/// The row a search found the card by: lit in a soft amber that reaches a
/// little past the text on both sides, so the text itself stays in line with
/// the other rows.
class _FoundRow extends StatelessWidget {
  static const double _bleed = 8;

  final Widget child;

  const _FoundRow({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: -_bleed,
          right: -_bleed,
          top: 0,
          bottom: 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: palette.searchMark.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: YiviSpace.x4),
          child: child,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Age — the highest age that is true and the lowest that is false, with one
// chip per age under it once expanded.
// ─────────────────────────────────────────────────────────────────────────────

class _AgeContent extends StatefulWidget {
  final AgeNode node;
  final CredentialCardLayout layout;
  const _AgeContent({required this.node, required this.layout});

  @override
  State<_AgeContent> createState() => _AgeContentState();
}

class _AgeContentState extends State<_AgeContent> {
  bool _expanded = false;

  String _summary(BuildContext context) {
    final ages = widget.node.ages;
    final over = ages.where((a) => a.over).map((a) => a.age).lastOrNull;
    final notOver = ages.where((a) => !a.over).map((a) => a.age).firstOrNull;

    final (key, params) = switch ((over, notOver)) {
      (final over?, final notOver?) => (
        "credential.age.over_and_not_over",
        {"over": "$over", "notOver": "$notOver"},
      ),
      (final over?, null) => ("credential.age.over", {"age": "$over"}),
      (null, final notOver?) => (
        "credential.age.not_over",
        {"age": "$notOver"},
      ),
      (null, null) => ("", <String, String>{}),
    };
    return context.tr(key, params);
  }

  @override
  Widget build(BuildContext context) {
    final layout = widget.layout;
    // Nothing to expand into when there is only one age.
    final canExpand = widget.node.ages.length > 1;

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        TranslatedText(
          "credential.age.label",
          style: attributeLabelStyle(context, layout: layout),
        ),
        Text(
          _summary(context),
          // The list's value colour, as every other value: light in dark mode.
          style: attributeValueStyle(
            context,
            AttributeColors.of(context).value,
            layout: layout,
          ),
        ),
        if (_expanded) ...[
          Padding(
            padding: const .only(top: _AgeChip.gap),
            child: TranslatedText(
              "credential.age.over_label",
              style: attributeLabelStyle(context, layout: layout),
            ),
          ),
          Padding(
            padding: const .only(top: _AgeChip.gap / 3, bottom: _AgeChip.gap),
            child: Wrap(
              spacing: _AgeChip.gap,
              runSpacing: _AgeChip.gap,
              children: [
                for (final entry in widget.node.ages) _AgeChip(entry: entry),
              ],
            ),
          ),
        ],
        if (canExpand)
          _AgeToggle(
            expanded: _expanded,
            onTap: () => setState(() => _expanded = !_expanded),
          ),
      ],
    );
  }
}

/// A pill that says whether the holder is over [AgeEntry.age]. The mark and the
/// colour repeat what the spoken label says.
class _AgeChip extends StatelessWidget {
  final AgeEntry entry;
  const _AgeChip({required this.entry});

  static const double gap = 6;
  static const double _height = 30;

  // Colours of the pills on board F_AgeConfirm, which no theme token has.
  static const _overText = Color(0xFF00602A);
  static const _notOverSurface = Color(0xFFF2F0EE);

  @override
  Widget build(BuildContext context) {
    // The board's neutralDark is 4.14:1 on _notOverSurface, below the 4.5:1 of
    // WCAG 1.4.3.
    final textColor = entry.over ? _overText : YiviPalette.of(context).heading;
    return Semantics(
      excludeSemantics: true,
      label: context.tr(
        entry.over ? "credential.age.chip_yes" : "credential.age.chip_no",
        {"age": "${entry.age}"},
      ),
      child: Container(
        height: _height,
        padding: const .symmetric(horizontal: YiviSpace.x8 + YiviSpace.x4 / 2),
        decoration: BoxDecoration(
          color: entry.over
              ? YiviPalette.of(context).successSurface
              : _notOverSurface,
          borderRadius: .circular(_height / 2),
        ),
        // Centers in the fixed height without stretching to the row's width.
        child: Center(
          widthFactor: 1,
          child: Text(
            "${entry.over ? "✓" : "–"} ${entry.age}",
            style: attributeLabelStyle(
              context,
            ).copyWith(fontWeight: FontWeight.w600, color: textColor),
          ),
        ),
      ),
    );
  }
}

/// Shows or hides the chips under the age.
class _AgeToggle extends StatelessWidget {
  final bool expanded;
  final VoidCallback onTap;
  const _AgeToggle({required this.expanded, required this.onTap});

  static const double _minHeight = 44;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      expanded: expanded,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _minHeight),
          child: Row(
            mainAxisSize: .min,
            spacing: YiviSpace.x4,
            children: [
              TranslatedText(
                expanded
                    ? "credential.age.hide_all"
                    : "credential.age.show_all",
                style: attributeLabelStyle(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: YiviPalette.of(context).link,
                ),
              ),
              ExcludeSemantics(
                child: RotatedBox(
                  quarterTurns: expanded ? 2 : 0,
                  child: SizedBox.square(
                    dimension: 16,
                    child: CustomPaint(
                      painter: _ChevronPainter(
                        color: YiviPalette.of(context).link,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChevronPainter extends CustomPainter {
  final Color color;
  _ChevronPainter({required this.color});

  static const _grid = 24.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _grid);
    canvas.drawPath(
      Path()
        ..moveTo(6, 9)
        ..lineTo(12, 15)
        ..lineTo(18, 9),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_ChevronPainter oldDelegate) => oldDelegate.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Array of primitives — label over one chip per value.
// ─────────────────────────────────────────────────────────────────────────────

class _PrimArrayContent extends StatelessWidget {
  final PrimArrayNode node;
  const _PrimArrayContent({required this.node});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        Text(node.label, style: attributeLabelStyle(context)),
        Padding(
          padding: const EdgeInsets.only(
            top: YiviSpace.x8,
            bottom: YiviSpace.x4,
          ),
          child: Wrap(
            spacing: YiviSpace.x8,
            runSpacing: YiviSpace.x8,
            children: [
              for (final v in node.values)
                Container(
                  constraints: const BoxConstraints(minHeight: 30),
                  padding: const EdgeInsets.symmetric(
                    horizontal: YiviSpace.x12,
                    vertical: YiviSpace.x4,
                  ),
                  decoration: ShapeDecoration(
                    color: palette.tint,
                    shape: StadiumBorder(
                      side: BorderSide(color: palette.outline),
                    ),
                  ),
                  child: Text(
                    formatAttributeValue(context, v),
                    // A value of the list, for readers of it (and tests).
                    key: const Key("attribute_array_value"),
                    style: palette
                        .body(14, weight: FontWeight.w600)
                        .copyWith(color: palette.heading),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
