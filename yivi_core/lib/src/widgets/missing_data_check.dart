import "package:material_ui/material_ui.dart";

import "../theme/theme.dart";
import "missing_data_icon.dart";

const _listCheckSize = 26.0;
const _badgeSize = 16.0;
const _badgeBorderWidth = 2.0;
const _badgeTickSize = 8.0;

/// The green circle with a white tick at the end of a row that is in the app.
class MissingDataCheck extends StatelessWidget {
  const MissingDataCheck({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return ExcludeSemantics(
      child: MissingDataIcon(
        size: _listCheckSize,
        lines: const [
          [Offset(7, 12.5), Offset(10.2, 15.7), Offset(17, 9)],
        ],
        strokeWidth: 2.4,
        color: theme.light,
        circleColor: theme.success,
        circleRadius: 11,
      ),
    );
  }
}

/// The small tick badge on the corner of a credential icon.
class MissingDataBadge extends StatelessWidget {
  const MissingDataBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Container(
      width: _badgeSize,
      height: _badgeSize,
      decoration: BoxDecoration(
        color: theme.success,
        shape: BoxShape.circle,
        border: Border.all(color: theme.light, width: _badgeBorderWidth),
      ),
      child: Center(
        child: MissingDataIcon(
          size: _badgeTickSize,
          lines: const [
            [Offset(4, 12.5), Offset(9, 17.5), Offset(20, 6.5)],
          ],
          strokeWidth: 4,
          color: theme.light,
        ),
      ),
    );
  }
}
