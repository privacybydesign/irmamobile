import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";

import "../theme/theme.dart";
import "../util/signature_message_text.dart";
import "irma_quote.dart";

/// Number of lines shown before a long signature message is collapsed behind a
/// "Read more" link, in the spirit of chat apps like WhatsApp.
const int _collapsedMaxLines = 8;

/// Messages no longer than this are always rendered in full (and keep going
/// through the markdown path). Comfortably below what [_collapsedMaxLines]
/// lines can hold at any realistic width, so such messages never need a toggle.
const int _shortMessageMaxLength = 200;

/// Renders a signature-session message safely.
///
/// Signature messages are arbitrary, requestor-controlled strings that may be
/// very large. Rendering them directly can freeze the UI thread (see
/// https://github.com/privacybydesign/irmamobile/issues/294), so this widget:
///
///  * inserts invisible soft line-break opportunities so the text layout engine
///    never blocks on a single huge "word";
///  * truncates long messages to a few lines ending in an ellipsis, with a
///    bold, coloured, tappable "Read more" link to reveal the full message
///    (chat-app style, à la WhatsApp). Once expanded, a "Read less" link
///    collapses it again.
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
    // Short messages render unchanged through the markdown quote path, so any
    // markdown keeps being formatted and the existing `IrmaQuote.quote` based
    // assertions keep working.
    if (widget.message.runes.length <= _shortMessageMaxLength) {
      return IrmaQuote(
        key: const Key("signature_message"),
        quote: renderableSignatureMessage(widget.message, expanded: true),
      );
    }

    return IrmaQuote(
      key: const Key("signature_message"),
      child: _buildTruncatableMessage(context),
    );
  }

  Widget _buildTruncatableMessage(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);

    // Match the styling IrmaQuote uses for its markdown body so the truncated
    // and non-truncated renders look the same.
    final baseStyle = context.yivi.card.quoteBody;
    final linkStyle = baseStyle.copyWith(
      fontWeight: FontWeight.bold,
      color: context.yivi.brand.link,
    );

    // The full message is always soft-broken (the #294 fix). The collapsed
    // preview is additionally bounded in length so the layout engine never
    // processes the whole (potentially huge) message just to render a few lines.
    final fullText = insertSoftBreaks(widget.message);
    final previewText = insertSoftBreaks(
      signatureMessagePreview(widget.message),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Does the collapsed preview overflow the line budget? If not, the
        // message fits and needs no truncation at this width.
        final painter = TextPainter(
          text: TextSpan(text: previewText, style: baseStyle),
          textDirection: Directionality.of(context),
          textScaler: textScaler,
          maxLines: _collapsedMaxLines,
          ellipsis: "…",
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;
        painter.dispose();

        if (!overflows) {
          return Text(
            fullText,
            key: const Key("signature_message_text"),
            style: baseStyle,
            textScaler: textScaler,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _expanded ? fullText : previewText,
              key: const Key("signature_message_text"),
              style: baseStyle,
              textScaler: textScaler,
              maxLines: _expanded ? null : _collapsedMaxLines,
              overflow: _expanded ? TextOverflow.clip : TextOverflow.ellipsis,
            ),
            SizedBox(height: context.yivi.spacing.small),
            GestureDetector(
              key: const Key("signature_message_toggle"),
              onTap: () => setState(() => _expanded = !_expanded),
              behavior: HitTestBehavior.opaque,
              child: Text(
                FlutterI18n.translate(
                  context,
                  _expanded ? "signature.read_less" : "signature.read_more",
                ),
                style: linkStyle,
              ),
            ),
          ],
        );
      },
    );
  }
}
