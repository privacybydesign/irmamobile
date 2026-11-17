import "package:material_ui/material_ui.dart";

import "../theme/yivi_palette.dart";
import "../theme/yivi_space.dart";

/// What stands at the end of a [ListRow].
enum RowTrailing { chevron, check, none }

/// A row of a list or group: an optional [leading] picture, the [title]
/// with a [subtitle] under it, an optional grey [value], and a chevron or a
/// check at the end. It lights up grey under the finger.
class ListRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;

  /// Grey text before the trailing, e.g. the current language.
  final String? value;
  final RowTrailing trailing;

  /// Wins over [trailing].
  final Widget? trailingWidget;
  final VoidCallback? onTap;

  /// What a detail pane shows: the row is tinted and its chevron blue.
  final bool selected;

  /// A destructive action: a red title, no chevron.
  final bool danger;

  /// When false the row is greyed out and ignores taps.
  final bool enabled;

  /// A link for screen readers (opens a page) rather than a button.
  final bool link;

  /// Extra space at the start, for a row that belongs to the one above.
  final double indent;
  final int? titleMaxLines;
  final int subtitleMaxLines;

  /// Read out instead of the row's texts.
  final String? semanticsLabel;

  /// A key on the subtitle, for tests.
  final Key? subtitleKey;

  /// A short list of one-line rows (the country picker): 52 high, its parts
  /// 12 apart.
  final bool dense;

  const ListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.value,
    this.trailing = RowTrailing.chevron,
    this.trailingWidget,
    this.onTap,
    this.selected = false,
    this.danger = false,
    this.enabled = true,
    this.link = false,
    this.indent = 0,
    this.titleMaxLines,
    this.subtitleMaxLines = 1,
    this.semanticsLabel,
    this.subtitleKey,
    this.dense = false,
  });

  /// The least height of a row, and of a [dense] one.
  static const double height = 60;
  static const double heightDense = 52;

  /// Its side, and the gap between its parts.
  static const double side = YiviSpace.x16;
  static const double gap = YiviSpace.x16;
  static const double gapDense = YiviSpace.x12;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final end =
        trailingWidget ??
        switch (danger ? RowTrailing.none : trailing) {
          RowTrailing.chevron => Icon(
            Icons.chevron_right,
            color: selected ? palette.link : palette.faint,
          ),
          RowTrailing.check => Icon(Icons.check_rounded, color: palette.link),
          RowTrailing.none => null,
        };
    final row = ConstrainedBox(
      constraints: BoxConstraints(minHeight: dense ? heightDense : height),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          side + indent,
          dense ? YiviSpace.x8 : YiviSpace.x12,
          YiviSpace.x12,
          dense ? YiviSpace.x8 : YiviSpace.x12,
        ),
        child: Row(
          spacing: dense ? gapDense : gap,
          children: [
            ?leading,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: titleMaxLines,
                    overflow: titleMaxLines == null
                        ? null
                        : TextOverflow.ellipsis,
                    style: palette
                        .body(
                          16,
                          weight: danger ? FontWeight.w600 : FontWeight.w400,
                        )
                        .copyWith(
                          color: danger ? palette.danger : palette.text,
                        ),
                  ),
                  if (subtitle case final subtitle?)
                    Text(
                      subtitle,
                      key: subtitleKey,
                      maxLines: subtitleMaxLines,
                      overflow: TextOverflow.ellipsis,
                      style: palette.paragraphSmall.copyWith(
                        height: 20 / 14,
                        color: palette.secondaryText,
                      ),
                    ),
                ],
              ),
            ),
            if (value case final value?)
              Text(
                value,
                style: palette.paragraphSmall.copyWith(
                  color: palette.secondaryText,
                ),
              ),
            ?end,
          ],
        ),
      ),
    );
    return Semantics(
      link: link,
      button: !link && onTap != null && semanticsLabel != null,
      enabled: enabled,
      selected: selected,
      label: semanticsLabel,
      excludeSemantics: semanticsLabel != null,
      onTap: semanticsLabel == null ? null : onTap,
      child: Material(
        // A picked row of a list with a pane is tinted; in a choice (a
        // check at the end) the check alone says it.
        color:
            selected &&
                trailingWidget == null &&
                trailing == RowTrailing.chevron
            ? palette.tint
            : Colors.transparent,
        child: IgnorePointer(
          ignoring: !enabled,
          child: Opacity(
            opacity: enabled ? 1 : 0.5,
            child: InkWell(onTap: onTap, child: row),
          ),
        ),
      ),
    );
  }
}
