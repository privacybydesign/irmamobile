import "dart:math";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:material_ui/material_ui.dart";

import "../../../package_name.dart";
import "../../providers/preferences_provider.dart";
import "../../theme/theme.dart";
import "../../widgets/translated_text.dart";

const double _illustrationSize = 132;
const double _maxContentWidth = 480;
const double _topSpacing = 24;
const double _headerSpacing = 10;
const double _chipRadius = 14;
const double _chipIconSpacing = 6;
const double _chipHorizontalSpacing = 12;
const double _routeRadius = 12;
const double _routeVerticalSpacing = 14;
const double _routeIconSpacing = 14;
const double _routeIconCircleSize = 40;
const double _routeIconSize = 22;
const double _chipIconSize = 16;
const double _routeTextSpacing = 2;
const Color _chipTextColor = Color(0xFF00602A);

// The scan button floats over the bottom of the tab and its top edge is about
// 33 px above the tab's bottom edge, so the arrow's tip stops above that.
const double _arrowTipClearance = 40;
const double _arrowStrokeWidth = 4;
const double _arrowHeadStrokeWidth = 2;

// The arrow is drawn from its tip: these are offsets from the tip.
const Offset _arrowStart = Offset(67, -142);
const Offset _arrowStartControl = Offset(97, -90);
const Offset _arrowTipControl = Offset(1, -78);
const Offset _arrowShaftEnd = Offset(0, -22);
const Offset _arrowHeadLeft = Offset(-14, -28);
const Offset _arrowHeadRight = Offset(14, -28);
const Offset _arrowHeadCurve = Offset(0, -21);
const double _arrowHeight = 142;

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
            padding: EdgeInsets.fromLTRB(
              sidePadding,
              _topSpacing,
              sidePadding,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: theme.defaultSpacing,
              children: [
                Column(
                  spacing: _headerSpacing,
                  children: [
                    ExcludeSemantics(
                      child: SvgPicture.asset(
                        yiviAsset("enrollment/introduction_1.svg"),
                        width: _illustrationSize,
                        height: _illustrationSize,
                      ),
                    ),
                    if (_showReadyChip) _ReadyChip(),
                    TranslatedText(
                      "data_tab.start.title",
                      style: theme.textTheme.displayMedium!.copyWith(
                        height: 32 / 24,
                      ),
                      textAlign: TextAlign.center,
                      isHeader: true,
                    ),
                  ],
                ),
                const _RouteCard(
                  iconAsset: "ui/route_phone.svg",
                  titleKey: "data_tab.start.website_title",
                  textKey: "data_tab.start.website_text",
                ),
                const _RouteCard(
                  iconAsset: "ui/route_scan.svg",
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
        borderRadius: BorderRadius.circular(_chipRadius),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: _chipHorizontalSpacing,
          vertical: theme.tinySpacing,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: _chipIconSpacing,
          children: [
            ExcludeSemantics(
              child: SvgPicture.asset(
                yiviAsset("ui/ready_check.svg"),
                width: _chipIconSize,
                height: _chipIconSize,
              ),
            ),
            Flexible(
              child: TranslatedText(
                "data_tab.start.ready",
                style: theme.textTheme.bodyMedium!.copyWith(
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: FontWeight.w700,
                  color: _chipTextColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final String iconAsset;
  final String titleKey;
  final String textKey;

  const _RouteCard({
    required this.iconAsset,
    required this.titleKey,
    required this.textKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.light,
        borderRadius: BorderRadius.circular(_routeRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            offset: const Offset(0, 1),
            blurRadius: 6,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: theme.defaultSpacing,
          vertical: _routeVerticalSpacing,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: _routeIconSpacing,
          children: [
            ExcludeSemantics(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.surfaceSecondary,
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(
                  dimension: _routeIconCircleSize,
                  child: Center(
                    child: SvgPicture.asset(
                      yiviAsset(iconAsset),
                      width: _routeIconSize,
                      height: _routeIconSize,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: _routeTextSpacing,
                children: [
                  TranslatedText(
                    titleKey,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 22 / 16,
                    ),
                    isHeader: true,
                  ),
                  TranslatedText(
                    textKey,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      fontSize: 15,
                      height: 21 / 15,
                      color: theme.neutralExtraDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
        constraints: const BoxConstraints(
          minHeight: _arrowHeight + _arrowTipClearance,
        ),
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
    final shaft = Path()
      ..moveTo(_arrowStart.dx, _arrowStart.dy)
      ..cubicTo(
        _arrowStartControl.dx,
        _arrowStartControl.dy,
        _arrowTipControl.dx,
        _arrowTipControl.dy,
        _arrowShaftEnd.dx,
        _arrowShaftEnd.dy,
      );
    final head = Path()
      ..moveTo(_arrowHeadLeft.dx, _arrowHeadLeft.dy)
      ..lineTo(0, 0)
      ..lineTo(_arrowHeadRight.dx, _arrowHeadRight.dy)
      ..quadraticBezierTo(
        _arrowHeadCurve.dx,
        _arrowHeadCurve.dy,
        _arrowHeadLeft.dx,
        _arrowHeadLeft.dy,
      )
      ..close();

    canvas.translate(size.width / 2, size.height - _arrowTipClearance);
    canvas.drawPath(
      shaft,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _arrowStrokeWidth
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(head, Paint()..color = color);
    canvas.drawPath(
      head,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _arrowHeadStrokeWidth
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_ArrowPainter oldDelegate) => oldDelegate.color != color;
}
