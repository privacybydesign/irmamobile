import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../theme/yivi_corners.dart";
import "../theme/yivi_palette.dart";
import "../util/i18n.dart";
import "glass/glass_dialog.dart";
import "glass/pill_buttons.dart";
import "status_body.dart";

enum ErrorType { general, expired, pairingRejected }

/// The middle of an error screen: a red (or, for an expired session, amber)
/// disc, a heading, what went wrong, a note asking to report it, and the
/// technical details behind a link that opens them in place.
class IrmaErrorScaffoldBody extends StatelessWidget {
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

  final ErrorType type;
  final String? details;
  final bool reportable;

  const IrmaErrorScaffoldBody({
    super.key,
    required this.type,
    this.details,
    this.reportable = false,
  });

  @override
  Widget build(BuildContext context) {
    final expired = type == ErrorType.expired;

    return StatusBody(
      icon: expired ? Icons.schedule_rounded : Icons.warning_rounded,
      tone: expired ? DialogTone.warning : DialogTone.danger,
      title: context.tr(_titleKeys[type]!),
      message: context.tr(_messageKeys[type]!),
      note: reportable ? context.tr("error.report") : null,
      footer: details == null ? null : ErrorDetails(details: details!),
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
            label: FlutterI18n.translate(
              context,
              _open ? "error.button_hide_error" : "error.button_show_error",
            ),
            onPressed: () => setState(() => _open = !_open),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: !_open
              ? const SizedBox(width: double.infinity)
              : Container(
                  key: const Key("error_details"),
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: YiviCorners.cardRadius,
                    boxShadow: [
                      BoxShadow(
                        color: palette.glassShadow,
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          FlutterI18n.translate(context, "error.details_title"),
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
