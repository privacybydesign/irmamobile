import "package:material_ui/material_ui.dart";

import "../../theme/yivi_palette.dart";

/// The big heading at the top of a sheet's page over the share screen
/// (Welk kaartje deel je?, Het bericht, …), with the one grey line under it
/// that says why. The bar's own title stays hidden until this has scrolled
/// under the bar (give [titleKey] to the page's `titleUnder`).
class SheetHeading extends StatelessWidget {
  final String title;
  final String? lead;
  final GlobalKey? titleKey;

  const SheetHeading({
    super.key,
    required this.title,
    this.lead,
    this.titleKey,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Semantics(
            header: true,
            child: Text(
              title,
              key: titleKey,
              style: palette
                  .display(24, weight: FontWeight.w700)
                  .copyWith(height: 30 / 24, color: palette.text),
            ),
          ),
          if (lead case final lead?) ...[
            const SizedBox(height: 8),
            Text(
              lead,
              key: const Key("sheet_heading_lead"),
              style: palette
                  .body(15)
                  .copyWith(height: 21 / 15, color: palette.secondaryText),
            ),
          ],
        ],
      ),
    );
  }
}
