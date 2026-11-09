import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../theme/yivi_corners.dart";
import "../theme/yivi_motion.dart";
import "../theme/yivi_palette.dart";
import "../util/signature_message_text.dart";
import "flight/yivi_flight.dart";
import "glass/glass_sheet.dart";
import "glass/sheet_heading.dart";

/// The message to sign as a quote: a white card, the text in Georgia 17/27
/// between big brand-red marks (“ top left, ” bottom right).
///
/// With [clamp], a message taller than that is cut after it with a fade, the
/// closing mark left off, and "Read the whole message ›" under it
/// ([onReadAll], the message sheet). A message is laid out with soft breaks
/// in long runs (issue #294), so a huge single word can't freeze the page.
class SignedMessage extends StatelessWidget {
  final String message;

  /// How tall the text may be before it is cut; null shows it all.
  final double? clamp;
  final VoidCallback? onReadAll;

  /// Extra decoration around the card (the done screen's paper shadow).
  final List<BoxShadow>? shadow;

  /// Room above the text, and below it (the paper on the done screen is
  /// roomier).
  final EdgeInsets padding;

  const SignedMessage({
    super.key,
    required this.message,
    this.clamp,
    this.onReadAll,
    this.shadow,
    this.padding = const EdgeInsets.fromLTRB(50, 18, 50, 20),
  });

  /// The share screen's clamp: about six lines.
  static const double shareClamp = 162;

  /// The done screen's paper: about five lines.
  static const double paperClamp = 135;

  static TextStyle textStyle(YiviPalette palette) => TextStyle(
    fontFamily: "Georgia",
    fontFamilyFallback: const ["serif"],
    fontSize: 17,
    height: 27 / 17,
    color: palette.text,
  );

  static TextStyle _mark(YiviPalette palette) => TextStyle(
    fontFamily: "Georgia",
    fontFamilyFallback: const ["serif"],
    fontSize: 64,
    height: 1,
    color: palette.primary,
  );

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final text = insertSoftBreaks(message);
    final style = textStyle(palette);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth - padding.horizontal;
        final limit = clamp;
        var cut = false;
        if (limit != null && width > 0) {
          final painter = TextPainter(
            text: TextSpan(text: text, style: style),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout(maxWidth: width);
          cut = painter.height > limit + 1;
          painter.dispose();
        }
        Widget body = Text(text, style: style);
        if (cut) {
          body = ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.55, 1],
              colors: [Color(0xFF000000), Color(0x00000000)],
            ).createShader(rect),
            child: SizedBox(
              height: limit,
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  maxHeight: double.infinity,
                  child: body,
                ),
              ),
            ),
          );
        }
        return DecoratedBox(
          key: const Key("signed_message"),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: YiviCorners.cardRadius,
            boxShadow: shadow,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      label: message,
                      excludeSemantics: true,
                      child: body,
                    ),
                    if (cut && onReadAll != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: _ReadAll(onTap: onReadAll!),
                      ),
                  ],
                ),
              ),
              Positioned(
                left: 14,
                top: 6,
                child: ExcludeSemantics(
                  child: Text("“", style: _mark(palette)),
                ),
              ),
              if (!cut)
                Positioned(
                  right: 14,
                  bottom: -14,
                  child: ExcludeSemantics(
                    child: Text("”", style: _mark(palette)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// "Read the whole message ›" under a cut message.
class _ReadAll extends StatelessWidget {
  final VoidCallback onTap;

  const _ReadAll({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Semantics(
      button: true,
      child: GestureDetector(
        key: const Key("signed_message_read_all"),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 36),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 2,
            children: [
              Text(
                FlutterI18n.translate(context, "signature.read_all"),
                style: palette
                    .body(15, weight: FontWeight.w600)
                    .copyWith(color: palette.link),
              ),
              Icon(Icons.chevron_right_rounded, size: 16, color: palette.link),
            ],
          ),
        ),
      ),
    );
  }
}

/// The whole message in a sheet of its own ("The message"), from the cut
/// message at [from] on the share screen or the done screen: the quote grows
/// from its place into the sheet's (420 ms), and shrinks back into it when
/// the sheet closes.
Future<void> showSignedMessageSheet({
  required BuildContext context,
  required String message,
  required String lead,
  GlobalKey? from,
}) {
  final into = GlobalKey(debugLabel: "message_sheet_quote");
  final titleKey = GlobalKey(debugLabel: "message_sheet_title");
  const flight = Duration(milliseconds: 420);

  void fly({required bool opening}) {
    final source = from;
    if (source == null) return;
    YiviFlight.start(
      context,
      from: opening ? source : into,
      to: YiviFlight.boxOf(opening ? into : source),
      keys: const [FlightKey(0, FlightKey.start), FlightKey(1, FlightKey.end)],
      duration: flight,
      curve: YiviMotion.ease,
      hide: [source, into],
      copy: (context, frame) => ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          maxHeight: double.infinity,
          child: SizedBox(
            width: frame.size.width,
            child: SignedMessage(message: message),
          ),
        ),
      ),
    );
  }

  // The quote is hidden in the sheet until the copy lands in it.
  if (from != null && !MediaQuery.disableAnimationsOf(context)) {
    YiviFlight.hide([into]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      YiviFlight.show([into]);
      fly(opening: true);
    });
  }
  return showGlassSheet<void>(
    context: context,
    motion: SheetMotion.share,
    builder: (context) => PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) fly(opening: false);
      },
      child: GlassSheetPage(
        key: const Key("message_sheet"),
        title: FlutterI18n.translate(context, "share.message_label"),
        titleUnder: titleKey,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeading(
              title: FlutterI18n.translate(context, "share.message_label"),
              lead: lead,
              titleKey: titleKey,
            ),
            const SizedBox(height: 16),
            FlightSpot(
              flightKey: into,
              child: SignedMessage(message: message),
            ),
          ],
        ),
      ),
    ),
  );
}
