import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_shadows.dart";
import "../../../util/adaptive_layout.dart";
import "../../../widgets/app_toast.dart";
import "../../../widgets/glass/glass_sheet.dart";
import "../../../widgets/glass/pill_buttons.dart";
import "../models/technical_details.dart";

/// The technical details of a request, for the curious: a subpage of the
/// requestor's sheet (see [RequestorTrustSheet]), reached from the last row
/// there; nothing in it is needed to decide.
class TechnicalDetailsSheet extends StatelessWidget {
  final List<TechGroup> groups;

  /// Back to the requestor's sheet.
  final VoidCallback? onBack;

  const TechnicalDetailsSheet({super.key, required this.groups, this.onBack});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    String t(String key) => FlutterI18n.translate(context, key);
    List<Widget> group(TechGroup g) => [
      Padding(
        padding: const EdgeInsets.fromLTRB(6, 18, 6, 8),
        child: Semantics(
          header: true,
          child: Text(
            g.title.toUpperCase(),
            style: palette
                .body(12.5, weight: FontWeight.w700)
                .copyWith(letterSpacing: 0.6, color: palette.secondaryText),
          ),
        ),
      ),
      DecoratedBox(
        decoration: YiviShadows.surfaceCard(palette),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, r) in g.rows.indexed) ...[
                if (i > 0)
                  Divider(height: 1, thickness: 1, color: palette.divider),
                _Row(row: r),
              ],
            ],
          ),
        ),
      ),
    ];
    return GlassSheetPage(
      title: t("share.tech.title"),
      onBack: onBack,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              t("share.tech.intro"),
              style: palette
                  .body(14)
                  .copyWith(height: 20 / 14, color: palette.secondaryText),
            ),
          ),
          if (useSheetColumns(context))
            // A phone held sideways: the groups in two columns.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [
                for (final side in [0, 1])
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (n, g) in groups.indexed)
                          if (n % 2 == side) ...group(g),
                      ],
                    ),
                  ),
              ],
            )
          else
            for (final g in groups) ...group(g),
          const SizedBox(height: 18),
          Center(
            child: PillButton(
              key: const Key("technical_details_copy"),
              label: t("share.tech.copy"),
              style: PillStyle.outlined,
              expand: false,
              size: PillSize.regular,
              leading: Icon(
                Icons.copy_rounded,
                size: 18,
                color: palette.heading,
              ),
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(text: technicalDetailsText(groups)),
                );
                showAppToast(context, t("share.tech.copied"));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final TechRow row;

  const _Row({required this.row});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final value = palette
        .body(14.5, weight: FontWeight.w600)
        .copyWith(height: 20 / 14.5, color: palette.text);
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 2,
          children: [
            Text(
              row.label,
              style: palette
                  .body(12.5)
                  .copyWith(height: 17 / 12.5, color: palette.secondaryText),
            ),
            SelectableText(
              row.value,
              style: row.mono
                  ? value.copyWith(
                      fontFamily: "monospace",
                      fontFamilyFallback: const ["Menlo", "Courier"],
                      letterSpacing: -0.1,
                    )
                  : value,
            ),
          ],
        ),
      ),
    );
  }
}
