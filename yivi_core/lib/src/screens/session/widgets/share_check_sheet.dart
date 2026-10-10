import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/schemaless_events.dart";
import "../../../theme/theme.dart";
import "../../../widgets/credential_card/yivi_credential_card_header.dart";
import "../../../widgets/translated_text.dart";
import "../../../widgets/yivi_themed_button.dart";
import "requestor_host.dart";

/// Why the user has to confirm before sharing.
enum ShareCheck { sensitive, unknownParty }

const _confirmDelay = Duration(seconds: 3);
const _fadeDuration = Duration(milliseconds: 200);
const _sheetTopRadius = 20.0;
const _buttonRadius = 8.0;
const _progressLineHeight = 2.0;

// The same 50% that YiviThemedButton applies to a disabled button.
const _disabledOpacity = 128 / 255;

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
      decoration: BoxDecoration(
        color: theme.backgroundSecondary,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(_sheetTopRadius),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: .all(theme.defaultSpacing),
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .stretch,
            children: [
              ExcludeSemantics(
                child: Icon(
                  sensitive
                      ? Icons.shield_outlined
                      : Icons.warning_amber_rounded,
                  size: 48,
                  color: sensitive ? theme.warning : theme.error,
                ),
              ),
              SizedBox(height: theme.smallSpacing),
              TranslatedText(
                "$keyPrefix.title",
                translationParams: {"host": requestorHost(requestor)},
                textAlign: TextAlign.center,
                style: credentialNameStyle(theme, 20),
                isHeader: true,
              ),
              SizedBox(height: theme.smallSpacing),
              TranslatedText(
                "$keyPrefix.text",
                translationParams: {"requestorName": requestor.name},
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              SizedBox(height: theme.mediumSpacing),
              _DelayedPrimaryButton(
                label: "$keyPrefix.confirm",
                onPressed: () => Navigator.of(context).pop(true),
              ),
              SizedBox(height: theme.smallSpacing),
              YiviThemedButton(
                key: const Key("share_check_decline"),
                label: "disclosure_permission.confirm_dialog.decline",
                style: .outlined,
                onPressed: () => Navigator.of(context).pop(false),
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
            onPressed: widget.onPressed,
          );
          if (reduceMotion) return button;

          return TweenAnimationBuilder<double>(
            tween: Tween(begin: _disabledOpacity, end: 1),
            duration: _fadeDuration,
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
