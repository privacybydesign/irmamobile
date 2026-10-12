import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/schemaless_events.dart";
import "../../../theme/theme.dart";
import "../../../widgets/translated_text.dart";
import "../../../widgets/yivi_themed_button.dart";
import "requestor_host.dart";

/// Why the user has to confirm before sharing.
enum ShareCheck { sensitive, unknownParty }

const _confirmDelay = Duration(seconds: 3);
const _fadeDuration = Duration(milliseconds: 200);
const _sheetTopRadius = 16.0;
const _buttonRadius = 8.0;
const _progressLineHeight = 3.0;
const _sheetGap = 14.0;
const _buttonGap = 8.0;
const _sheetPadding = 20.0;
const _sheetTopPadding = 12.0;
const _buttonsTopMargin = 6.0;
const _handleWidth = 40.0;
const _handleHeight = 4.0;
const _badgeSize = 52.0;
const _badgeIconSize = 26.0;
const _titleSize = 22.0;
const _titleHeight = 30 / _titleSize;
const _outlineWidth = 1.0;
const _scrimOpacity = 0.45;

// The board's amber for the sensitive data sheet. The theme has no surface
// and ink of this colour.
const _amberSurface = Color(0xFFFDF1DC);
const _amberInk = Color(0xFF7A4B00);

// The look of the button while it waits: 40%, which is 102 of 255.
const _waitAlpha = 102;
const _waitOpacity = _waitAlpha / 255;

/// Asks the user to confirm sharing. Completes with true when they share.
Future<bool> showShareCheckSheet({
  required BuildContext context,
  required ShareCheck check,
  required TrustedParty requestor,
}) async {
  final shared = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: _scrimOpacity),
    builder: (_) => _ShareCheckSheet(check: check, requestor: requestor),
  );

  return shared ?? false;
}

class _ShareCheckSheet extends StatelessWidget {
  final ShareCheck check;
  final TrustedParty requestor;

  const _ShareCheckSheet({required this.check, required this.requestor});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final sensitive = check == ShareCheck.sensitive;
    final keyPrefix = switch (check) {
      ShareCheck.sensitive => "disclosure_permission.share_v2.check_sensitive",
      ShareCheck.unknownParty =>
        "disclosure_permission.share_v2.check_unknown_party",
    };

    return Container(
      key: const Key("share_check_sheet"),
      decoration: BoxDecoration(
        color: theme.light,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(_sheetTopRadius),
        ),
      ),
      // The board's 32 px below the buttons is the whole bottom edge, so the
      // system inset counts towards it.
      child: SafeArea(
        top: false,
        minimum: .fromLTRB(
          _sheetPadding,
          _sheetTopPadding,
          _sheetPadding,
          theme.largeSpacing,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .start,
            spacing: _sheetGap,
            children: [
              Align(
                child: Container(
                  key: const Key("share_check_handle"),
                  width: _handleWidth,
                  height: _handleHeight,
                  decoration: BoxDecoration(
                    color: theme.neutralLight,
                    borderRadius: BorderRadius.circular(_handleHeight / 2),
                  ),
                ),
              ),
              Padding(
                padding: .only(top: theme.smallSpacing),
                child: ExcludeSemantics(
                  child: Container(
                    key: const Key("share_check_badge"),
                    width: _badgeSize,
                    height: _badgeSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: sensitive ? _amberSurface : theme.errorSurface,
                    ),
                    child: Icon(
                      sensitive ? Icons.gpp_maybe_outlined : Icons.help_outline,
                      size: _badgeIconSize,
                      color: sensitive ? _amberInk : theme.error,
                    ),
                  ),
                ),
              ),
              TranslatedText(
                "$keyPrefix.title",
                translationParams: {"host": requestorHost(requestor)},
                style: theme.textTheme.displayMedium!.copyWith(
                  fontSize: _titleSize,
                  height: _titleHeight,
                ),
                isHeader: true,
              ),
              TranslatedText(
                "$keyPrefix.text",
                translationParams: {"requestorName": requestor.name},
                style: theme.textTheme.bodyMedium,
              ),
              Padding(
                padding: .only(top: _buttonsTopMargin),
                child: Column(
                  crossAxisAlignment: .stretch,
                  spacing: _buttonGap,
                  children: [
                    _DelayedPrimaryButton(
                      label: "$keyPrefix.confirm",
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                    YiviThemedButton(
                      key: const Key("share_check_decline"),
                      label: "disclosure_permission.confirm_dialog.decline",
                      style: .outlined,
                      size: YiviButtonSize.tall,
                      outlineWidth: _outlineWidth,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A button that looks disabled for [_confirmDelay], so it cannot be tapped
/// through without reading. A white line along the bottom edge fills while it
/// waits, then the button fades to full colour. With reduced motion there is
/// no line and no fade, but the wait stays.
class _DelayedPrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;

  const _DelayedPrimaryButton({required this.label, required this.onPressed});

  @override
  State<_DelayedPrimaryButton> createState() => _DelayedPrimaryButtonState();
}

class _DelayedPrimaryButtonState extends State<_DelayedPrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wait;

  @override
  void initState() {
    super.initState();
    // With reduced motion the default behaviour cuts the duration to 5%.
    _wait = AnimationController(
      vsync: this,
      duration: _confirmDelay,
      animationBehavior: AnimationBehavior.preserve,
    )..forward();
  }

  @override
  void dispose() {
    _wait.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return AnimatedBuilder(
      animation: _wait,
      builder: (context, _) {
        if (_wait.isCompleted) {
          final button = YiviThemedButton(
            key: const Key("share_check_confirm"),
            label: widget.label,
            size: YiviButtonSize.tall,
            onPressed: widget.onPressed,
          );
          if (reduceMotion) return button;

          return TweenAnimationBuilder<double>(
            tween: Tween(begin: _waitOpacity, end: 1),
            duration: _fadeDuration,
            curve: Curves.easeOut,
            builder: (_, opacity, child) =>
                Opacity(opacity: opacity, child: child),
            child: button,
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(_buttonRadius),
          child: Stack(
            children: [
              YiviThemedButton(
                key: const Key("share_check_confirm"),
                label: widget.label,
                size: YiviButtonSize.tall,
                disabledAlpha: _waitAlpha,
                onPressed: null,
              ),
              if (!reduceMotion)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: _progressLineHeight,
                  child: FractionallySizedBox(
                    key: const Key("share_check_progress"),
                    alignment: Alignment.centerLeft,
                    widthFactor: _wait.value,
                    child: ColoredBox(color: IrmaTheme.of(context).light),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
