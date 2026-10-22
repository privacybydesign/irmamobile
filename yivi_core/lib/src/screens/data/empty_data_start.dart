import "dart:math";

import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../theme/yivi_corners.dart";
import "../../theme/yivi_palette.dart";
import "../../util/navigation.dart";
import "../../util/tablet.dart";
import "../../widgets/translated_text.dart";
import "../add_data/add_data_sheet.dart";
import "../home/widgets/irma_qr_scan_button.dart";

/// Widest the upright empty state is, as the rest of the tab.
const double _maxContentWidth = 640;

/// The empty Data tab, held upright: "No data yet" and the three ways to get
/// the first data.
class EmptyDataStart extends StatelessWidget {
  const EmptyDataStart({super.key});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + 112;
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = max(16.0, (constraints.maxWidth - _maxContentWidth) / 2);
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(side, 48, side, bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const EmptyDataTitle(),
              const SizedBox(height: 32),
              const EmptyDataOptions(rail: false),
            ],
          ),
        );
      },
    );
  }
}

/// "No data yet" and what adds data, centred.
class EmptyDataTitle extends StatelessWidget {
  const EmptyDataTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final tablet = context.isTabletDevice;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TranslatedText(
          "data_tab.start.title",
          isHeader: true,
          textAlign: TextAlign.center,
          style: palette
              .display(tablet ? 28 : 24, weight: FontWeight.w700)
              .copyWith(height: tablet ? 36 / 28 : 32 / 24),
        ),
        const SizedBox(height: 6),
        TranslatedText(
          "data_tab.start.text",
          textAlign: TextAlign.center,
          style: palette
              .body(15)
              .copyWith(color: palette.secondaryText, height: 22 / 15),
        ),
      ],
    );
  }
}

/// The empty Data tab next to its details pane (a tablet, a phone held
/// sideways): the pane offers the three ways to get started.
class EmptyDataPane extends StatelessWidget {
  const EmptyDataPane({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Text(
                  FlutterI18n.translate(
                    context,
                    "data_tab.start.get_started",
                  ).toUpperCase(),
                  style: palette
                      .body(12.5, weight: FontWeight.w700)
                      .copyWith(
                        letterSpacing: 0.6,
                        color: palette.secondaryText,
                      ),
                ),
              ),
              const EmptyDataOptions(rail: true),
            ],
          ),
        ),
      ),
    );
  }
}

/// Got a QR code?, a website on this device, and adding data yourself.
/// [rail] says where the Scan button is: under the menu at the left, or at
/// the bottom.
class EmptyDataOptions extends StatelessWidget {
  final bool rail;

  const EmptyDataOptions({super.key, required this.rail});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final tablet = context.isTabletDevice;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        _Option(
          key: const Key("empty_data_qr"),
          icon: Icons.qr_code_scanner_rounded,
          tileColor: palette.errorSurface,
          iconColor: palette.primary,
          titleKey: "data_tab.start.qr_title",
          textKey: rail
              ? "data_tab.start.qr_text_rail"
              : "data_tab.start.qr_text_bar",
          onTap: () => openQrCodeScanner(context),
        ),
        _Option(
          key: const Key("empty_data_website"),
          icon: Icons.open_in_browser_rounded,
          tileColor: palette.infoSurface,
          iconColor: palette.link,
          titleKey: tablet
              ? "data_tab.start.website_title_tablet"
              : "data_tab.start.website_title_phone",
          textKey: "data_tab.start.website_text",
          onTap: context.pushBackToWebsiteScreen,
        ),
        _Option(
          key: const Key("empty_data_add"),
          icon: Icons.add_rounded,
          tileColor: palette.successSurface,
          iconColor: palette.successText,
          titleKey: "data_tab.start.add_title",
          textKey: "data_tab.start.add_text",
          onTap: () => showAddDataSheet(context),
        ),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  final IconData icon;
  final Color tileColor;
  final Color iconColor;
  final String titleKey;
  final String textKey;
  final VoidCallback onTap;

  const _Option({
    super.key,
    required this.icon,
    required this.tileColor,
    required this.iconColor,
    required this.titleKey,
    required this.textKey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Semantics(
      button: true,
      child: Material(
        color: palette.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(YiviCorners.card)),
        ),
        shadowColor: const Color(0x29000000),
        elevation: 1,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashFactory: NoSplash.splashFactory,
          highlightColor: palette.divider,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              spacing: 14,
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: tileColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 24, color: iconColor),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TranslatedText(
                        titleKey,
                        style: palette.display(16, weight: FontWeight.w600),
                      ),
                      TranslatedText(
                        textKey,
                        style: palette
                            .body(13.5)
                            .copyWith(color: palette.secondaryText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
