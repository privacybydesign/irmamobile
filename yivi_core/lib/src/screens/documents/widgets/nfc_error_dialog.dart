import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:go_router/go_router.dart";

import "../../../sentry/sentry.dart";
import "../../../theme/theme.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "../../../widgets/irma_dialog.dart";
import "../../../widgets/translated_text.dart";

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
    final theme = IrmaTheme.of(context);
    return YiviDialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: .min,
          mainAxisAlignment: .spaceBetween,
          crossAxisAlignment: .start,
          children: [
            IrmaAppBar(
              titleTranslationKey: "error.details_title",
              leading: null,
            ),
            Row(
              mainAxisSize: .max,
              mainAxisAlignment: widget.sensitiveLogs == null
                  ? .end
                  : .spaceBetween,
              children: [
                if (widget.sensitiveLogs != null)
                  Row(
                    children: [
                      Checkbox(
                        value: _showSensitiveLogs,
                        onChanged: (_) {
                          setState(() {
                            _showSensitiveLogs = !_showSensitiveLogs;
                          });
                        },
                      ),
                      TranslatedText("error.show_sensitive_data"),
                    ],
                  ),
                IconButton(
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
                  icon: Icon(Icons.copy),
                ),
              ],
            ),
            Flexible(
              fit: .loose,
              child: SingleChildScrollView(
                padding: .all(theme.defaultSpacing),
                child: Text(
                  _showSensitiveLogs ? widget.sensitiveLogs! : widget.logs,
                ),
              ),
            ),
            IrmaBottomBar(
              primaryButtonLabel: "error.button_send_to_irma",
              secondaryButtonLabel: "error.button_ok",
              // Can't share logs when sensitive data is enabled,
              // so the user understand they'll never send sensitive data to our Sentry logs
              onPrimaryPressed: _showSensitiveLogs
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
              onSecondaryPressed: () {
                context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
