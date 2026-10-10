import "dart:math";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:material_ui/material_ui.dart";

import "../../../package_name.dart";
import "../../providers/preferences_provider.dart";
import "../../theme/theme.dart";
import "../../widgets/irma_card.dart";
import "../../widgets/translated_text.dart";

const double _illustrationHeight = 132;
const double _maxContentWidth = 480;
const double _routeIconSize = 32;

// The scan button floats over the bottom of the tab: its top edge is 23 px
// above the tab's bottom edge, so the arrow stops a little above that.
const double _qrButtonClearance = 32;
const double _arrowMinHeight = 96;
const double _arrowStrokeWidth = 3;
const double _arrowHeadSize = 12;

/// Empty state of the data tab with onboarding v2: the two ways to add the
/// first data. Shown until the first credential is added.
class EmptyDataRoutes extends ConsumerStatefulWidget {
  const EmptyDataRoutes({super.key});

  @override
  ConsumerState<EmptyDataRoutes> createState() => _EmptyDataRoutesState();
}

class _EmptyDataRoutesState extends ConsumerState<EmptyDataRoutes> {
  bool _showReadyChip = false;

  @override
  void initState() {
    super.initState();
    _consumeReadyChip();
  }

  // The chip is for the first visit after onboarding only, so the marker is
  // cleared as soon as it is shown and this state remembers it for the visit.
  Future<void> _consumeReadyChip() async {
    final preferences = ref.read(preferencesProvider);
    final pending = await preferences.getReadyChipPending().first;
    if (!pending) return;

    if (mounted) setState(() => _showReadyChip = true);
    await preferences.markReadyChipShown();
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    // The width is capped with padding rather than a ConstrainedBox: the
    // sliver measures its child's intrinsic height, and a ConstrainedBox does
    // not narrow the width it passes on, so the text would wrap differently
    // there than where it is laid out.
    final sidePadding = max(
      theme.defaultSpacing,
      (MediaQuery.sizeOf(context).width - _maxContentWidth) / 2,
    );

    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: sidePadding,
              vertical: theme.defaultSpacing,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: ExcludeSemantics(
                    child: SvgPicture.asset(
                      yiviAsset("enrollment/introduction_1.svg"),
                      height: _illustrationHeight,
                    ),
                  ),
                ),
                SizedBox(height: theme.defaultSpacing),
                if (_showReadyChip) ...[
                  Center(child: _ReadyChip()),
                  SizedBox(height: theme.smallSpacing),
                ],
                TranslatedText(
                  "data_tab.start.title",
                  style: theme.textTheme.displayLarge,
                  textAlign: TextAlign.center,
                  isHeader: true,
                ),
                SizedBox(height: theme.defaultSpacing),
                const _RouteCard(
                  icon: Icons.smartphone_rounded,
                  titleKey: "data_tab.start.website_title",
                  textKey: "data_tab.start.website_text",
                ),
                SizedBox(height: theme.smallSpacing),
                const _RouteCard(
                  icon: Icons.qr_code_scanner_rounded,
                  titleKey: "data_tab.start.qr_title",
                  textKey: "data_tab.start.qr_text",
                ),
                const Expanded(child: _ArrowToScanButton()),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadyChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.successSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: theme.defaultSpacing,
          vertical: theme.tinySpacing,
        ),
        child: TranslatedText(
          "data_tab.start.ready",
          style: theme.textTheme.headlineMedium,
        ),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final IconData icon;
  final String titleKey;
  final String textKey;

  const _RouteCard({
    required this.icon,
    required this.titleKey,
    required this.textKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return IrmaCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(icon, size: _routeIconSize, color: theme.primary),
          ),
          SizedBox(width: theme.defaultSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TranslatedText(titleKey, style: theme.textTheme.headlineMedium),
                SizedBox(height: theme.tinySpacing),
                TranslatedText(textKey, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Fills the space under the cards with a curved arrow that ends above the
/// scan button, which sits in the middle of the bottom bar.
class _ArrowToScanButton extends StatelessWidget {
  const _ArrowToScanButton();

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return ExcludeSemantics(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _arrowMinHeight),
        child: CustomPaint(painter: _ArrowPainter(color: theme.primary)),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final Color color;

  const _ArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final start = Offset(size.width * 0.75, 0);
    final tip = Offset(size.width / 2, size.height - _qrButtonClearance);
    final halfHeight = (tip.dy - start.dy) / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _arrowStrokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Leaves the card and arrives at the button both pointing straight down.
    final shaft = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        start.dx,
        start.dy + halfHeight,
        tip.dx,
        tip.dy - halfHeight,
        tip.dx,
        tip.dy,
      );
    final head = Path()
      ..moveTo(tip.dx - _arrowHeadSize, tip.dy - _arrowHeadSize)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(tip.dx + _arrowHeadSize, tip.dy - _arrowHeadSize);

    canvas.drawPath(shaft, paint);
    canvas.drawPath(head, paint);
  }

  @override
  bool shouldRepaint(_ArrowPainter oldDelegate) => oldDelegate.color != color;
}
