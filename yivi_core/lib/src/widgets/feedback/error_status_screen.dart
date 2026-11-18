import "package:material_ui/material_ui.dart";

import "../../theme/yivi_corners.dart";
import "../../theme/yivi_edges.dart";
import "../../theme/yivi_motion.dart";
import "../../theme/yivi_palette.dart";
import "../../theme/yivi_space.dart";
import "../../theme/yivi_tone.dart";
import "../../util/i18n.dart";
import "../buttons/pill_buttons.dart";
import "status_screen.dart";

enum ErrorType { general, expired, pairingRejected }

/// An error screen: a red (or, for an expired session, amber) disc, a
/// heading, what went wrong, a note asking to report it, and the technical
/// details behind a link that opens them in place.
class ErrorStatusScreen extends StatelessWidget {
  static const _titleKeys = {
    ErrorType.general: "error.title",
    ErrorType.expired: "error.expired_title",
    ErrorType.pairingRejected: "error.title",
  };

  static const _messageKeys = {
    ErrorType.general: "error.types.general",
    ErrorType.expired: "error.types.expired",
    ErrorType.pairingRejected: "error.types.pairing_rejected",
  };

  final PreferredSizeWidget? appBar;
  final ErrorType type;
  final String? details;
  final bool reportable;
  final Widget? actions;

  const ErrorStatusScreen({
    super.key,
    this.appBar,
    required this.type,
    this.details,
    this.reportable = false,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final expired = type == ErrorType.expired;
    return StatusScreen(
      appBar: appBar,
      icon: expired ? Icons.schedule_rounded : Icons.warning_rounded,
      tone: expired ? YiviTone.warning : YiviTone.danger,
      title: context.tr(_titleKeys[type]!),
      message: context.tr(_messageKeys[type]!),
      note: reportable ? context.tr("error.report") : null,
      footer: details == null ? null : ErrorDetails(details: details!),
      actions: actions,
    );
  }
}

/// "Show technical details": opens the error message in place, in a card
/// with a monospace text that can be selected and copied.
class ErrorDetails extends StatefulWidget {
  final String details;

  const ErrorDetails({super.key, required this.details});

  @override
  State<ErrorDetails> createState() => _ErrorDetailsState();
}

class _ErrorDetailsState extends State<ErrorDetails> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: TextLink(
            key: const Key("error_details_toggle"),
            label: context.tr(
              _open ? "error.button_hide_error" : "error.button_show_error",
            ),
            onPressed: () => setState(() => _open = !_open),
          ),
        ),
        AnimatedSize(
          duration: YiviMotion.quick,
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: !_open
              ? const SizedBox(width: double.infinity)
              : Container(
                  key: const Key("error_details"),
                  margin: const EdgeInsets.only(top: YiviSpace.x12),
                  padding: const EdgeInsets.all(YiviSpace.x16),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: YiviCorners.cardRadius,
                    border: Border.fromBorderSide(YiviEdges.block(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: YiviSpace.x8,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          context.tr("error.details_title"),
                          style: palette.display(14),
                        ),
                      ),
                      SelectableText(
                        widget.details,
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontFamily: "monospace",
                          fontFamilyFallback: const ["Menlo", "Courier"],
                          fontSize: 12,
                          height: 18 / 12,
                          color: palette.heading,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
