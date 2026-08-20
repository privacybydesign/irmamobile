/// Utilities for safely rendering user-provided signature-session messages.
///
/// A signature message is an arbitrary, requestor-controlled string that can be
/// very large (the IRMA server happily accepts tens of thousands of
/// characters). Rendering such a message directly can freeze the UI thread: a
/// long run of characters without any line-break opportunity (for example
/// `0123456789...` with no spaces) makes Flutter's line-breaking algorithm do
/// pathological work, blocking the main isolate for a long time.
///
/// See https://github.com/privacybydesign/irmamobile/issues/294.
library;

/// Maximum number of characters rendered for the inline signature-message
/// preview. Longer messages are truncated, with the full text available on
/// demand.
const int maxInlineSignatureMessageLength = 5000;

/// Longest run of consecutive non-whitespace characters kept intact before a
/// soft line-break opportunity is inserted.
const int maxUnbrokenRunLength = 30;

/// Zero-width space: an invisible character that the text layout engine may use
/// as a line-break opportunity. Inserting it does not change how the message
/// looks to the user, but it prevents a single huge "word" from blocking the
/// UI thread.
const String zeroWidthSpace = "​";

/// Whether [message] is longer than the inline preview limit and therefore
/// rendered truncated by default.
bool signatureMessageIsTruncated(
  String message, {
  int maxLength = maxInlineSignatureMessageLength,
}) => message.runes.length > maxLength;

/// The inline preview of [message]: at most [maxLength] characters. Returns the
/// message unchanged when it is short enough.
String signatureMessagePreview(
  String message, {
  int maxLength = maxInlineSignatureMessageLength,
}) {
  final runes = message.runes.toList();
  if (runes.length <= maxLength) return message;
  return String.fromCharCodes(runes.take(maxLength));
}

bool _isWhitespace(int rune) =>
    rune == 0x20 || // space
    rune == 0x09 || // tab
    rune == 0x0A || // newline
    rune == 0x0D || // carriage return
    rune == 0x0C || // form feed
    rune == 0x0B; // vertical tab

/// Inserts zero-width-space break opportunities into long unbroken runs of
/// [text] so that the layout engine never blocks the UI thread on a single
/// huge "word". Whitespace already provides break opportunities, so only runs
/// of non-whitespace longer than [maxRunLength] are split. The visible text is
/// unchanged because [zeroWidthSpace] renders as nothing.
String insertSoftBreaks(
  String text, {
  int maxRunLength = maxUnbrokenRunLength,
}) {
  if (maxRunLength <= 0) return text;
  final buffer = StringBuffer();
  var run = 0;
  for (final rune in text.runes) {
    if (_isWhitespace(rune)) {
      run = 0;
    } else {
      if (run >= maxRunLength) {
        buffer.write(zeroWidthSpace);
        run = 0;
      }
      run++;
    }
    buffer.writeCharCode(rune);
  }
  return buffer.toString();
}

/// Prepares [message] for inline rendering: truncates it to the preview limit
/// (when [expanded] is false) and inserts soft-break opportunities so that even
/// pathological single-token messages render responsively.
String renderableSignatureMessage(String message, {bool expanded = false}) {
  final shown = expanded ? message : signatureMessagePreview(message);
  return insertSoftBreaks(shown);
}
