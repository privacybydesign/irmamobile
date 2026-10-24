import "package:flutter/services.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";

import "../../../../sentry/sentry.dart";
import "../../../../theme/yivi_palette.dart";
import "../../../../util/i18n.dart";
import "../../../../widgets/glass/glass_dialog.dart";
import "../../../../widgets/glass/pill_buttons.dart";
import "../../../../widgets/translated_text.dart";

class NfcErrorDialog extends StatefulWidget {
  const NfcErrorDialog({required this.logs, this.sensitiveLogs});

  final String logs;
  final String? sensitiveLogs;

  @override
  State<NfcErrorDialog> createState() => _NfcErrorDialogState();
}

class _NfcErrorDialogState extends State<NfcErrorDialog> {
  bool _showSensitiveLogs = false;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return GlassDialog(
      title: context.tr("error.details_title"),
      body: Column(
        crossAxisAlignment: .stretch,
        children: [
          Row(
            mainAxisAlignment: widget.sensitiveLogs == null
                ? .end
                : .spaceBetween,
            children: [
              if (widget.sensitiveLogs != null)
                Flexible(
                  child: Row(
                    children: [
                      Checkbox(
                        value: _showSensitiveLogs,
                        onChanged: (_) {
                          setState(() {
                            _showSensitiveLogs = !_showSensitiveLogs;
                          });
                        },
                      ),
                      Flexible(
                        child: TranslatedText("error.show_sensitive_data"),
                      ),
                    ],
                  ),
                ),
              PlainIconButton(
                icon: Icons.copy,
                semanticsLabel: MaterialLocalizations.of(
                  context,
                ).copyButtonLabel,
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(
                      text: _showSensitiveLogs
                          ? widget.sensitiveLogs!
                          : widget.logs,
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Copied to clipboard!")),
                  );
                },
              ),
            ],
          ),
          // The log scrolls on its own, so the buttons stay in view.
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.4,
            ),
            child: SingleChildScrollView(
              child: Text(
                _showSensitiveLogs ? widget.sensitiveLogs! : widget.logs,
                style: palette.body(13).copyWith(color: palette.secondaryText),
              ),
            ),
          ),
        ],
      ),
      actions: [
        FancyPillButton(
          label: context.tr("error.button_send_to_irma"),
          size: PillSize.regular,
          // Can't share logs when sensitive data is enabled, so the user
          // understands they'll never send sensitive data to our Sentry logs.
          onPressed: _showSensitiveLogs
              ? null
              : () async {
                  reportError(
                    Exception(widget.logs),
                    StackTrace.current,
                    userInitiated: true,
                  );
                  if (context.mounted) {
                    context.pop();
                  }
                },
        ),
        PillButton(
          label: context.tr("error.button_ok"),
          style: PillStyle.text,
          size: PillSize.regular,
          onPressed: () => context.pop(),
        ),
      ],
    );
  }
}
