import "package:flutter/material.dart";

import "../theme/theme.dart";
import "../util/signature_message_text.dart";
import "irma_quote.dart";
import "translated_text.dart";

/// Renders a signature-session message safely.
///
/// Signature messages are arbitrary, requestor-controlled strings that may be
/// very large. Rendering them directly can freeze the UI thread (see
/// https://github.com/privacybydesign/irmamobile/issues/294), so this widget:
///
///  * inserts invisible soft line-break opportunities so the text layout engine
///    never blocks on a single huge "word";
///  * truncates very long messages to an inline preview, with a button to
///    reveal the full message on demand.
class SignatureMessage extends StatefulWidget {
  final String message;

  const SignatureMessage({super.key, required this.message});

  @override
  State<SignatureMessage> createState() => _SignatureMessageState();
}

class _SignatureMessageState extends State<SignatureMessage> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final isTruncated = signatureMessageIsTruncated(widget.message);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IrmaQuote(
          key: const Key("signature_message"),
          quote: renderableSignatureMessage(
            widget.message,
            expanded: _expanded || !isTruncated,
          ),
        ),
        if (isTruncated) ...[
          SizedBox(height: theme.smallSpacing),
          TextButton(
            key: const Key("signature_message_toggle"),
            onPressed: () => setState(() => _expanded = !_expanded),
            child: TranslatedText(
              _expanded ? "signature.show_less" : "signature.show_full",
            ),
          ),
        ],
      ],
    );
  }
}
