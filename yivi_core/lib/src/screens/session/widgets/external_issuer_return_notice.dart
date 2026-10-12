import "package:material_ui/material_ui.dart";

import "../../../theme/theme.dart";
import "../../../widgets/translated_text.dart";

const _notice = Duration(seconds: 4);
const _arrowSize = 18.0;
const _iconGap = 10.0;
const _enterOffset = -10.0;
const _paddingVertical = 10.0;
const _paddingHorizontal = 14.0;
const _textLineHeight = 20.0;

// Where the notice fades in and out, as parts of [_notice].
const _hiddenWeight = 5.0;
const _fadeInWeight = 10.0;
const _shownWeight = 70.0;
const _fadeOutWeight = 15.0;
const _restingValue = 0.5;

/// A short note that the user is back from the issuer's website. It slides in,
/// stays a moment and fades out, and keeps its place so the screen does not
/// jump. With animations off it stays in view.
class ExternalIssuerReturnNotice extends StatefulWidget {
  final String issuer;

  const ExternalIssuerReturnNotice({super.key, required this.issuer});

  @override
  State<ExternalIssuerReturnNotice> createState() =>
      _ExternalIssuerReturnNoticeState();
}

class _ExternalIssuerReturnNoticeState extends State<ExternalIssuerReturnNotice>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _notice,
  );

  late final Animation<double> _opacity = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(0), weight: _hiddenWeight),
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: _fadeInWeight,
    ),
    TweenSequenceItem(tween: ConstantTween(1), weight: _shownWeight),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 0.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: _fadeOutWeight,
    ),
  ]).animate(_controller);

  late final Animation<double> _offset = TweenSequence<double>([
    TweenSequenceItem(
      tween: ConstantTween(_enterOffset),
      weight: _hiddenWeight,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: _enterOffset,
        end: 0.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: _fadeInWeight,
    ),
    TweenSequenceItem(
      tween: ConstantTween(0),
      weight: _shownWeight + _fadeOutWeight,
    ),
  ]).animate(_controller);

  bool _configured = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_configured) return;

    _configured = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = _restingValue;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    final notice = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: _paddingHorizontal,
        vertical: _paddingVertical,
      ),
      decoration: BoxDecoration(
        color: theme.light,
        borderRadius: theme.borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            offset: const Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        spacing: _iconGap,
        children: [
          ExcludeSemantics(
            child: Icon(Icons.arrow_back, size: _arrowSize, color: theme.link),
          ),
          Expanded(
            child: TranslatedText(
              "external_issuer.returned",
              translationParams: {"issuer": widget.issuer},
              style: theme.textTheme.bodySmall!.copyWith(
                height: _textLineHeight / 14,
                color: theme.dark,
              ),
            ),
          ),
        ],
      ),
    );

    return Semantics(
      liveRegion: true,
      child: FadeTransition(
        opacity: _opacity,
        child: AnimatedBuilder(
          animation: _offset,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, _offset.value),
            child: child,
          ),
          child: notice,
        ),
      ),
    );
  }
}
