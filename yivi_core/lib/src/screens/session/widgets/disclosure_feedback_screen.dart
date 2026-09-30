import "package:intl/intl.dart";
import "package:material_ui/material_ui.dart";

import "../../../widgets/action_feedback.dart";

/// The outcomes a finished disclosure can be reported as.
///
/// [zeroKnowledge] is a success, not a separate result: the data was disclosed.
/// It is its own case because what the user should be told differs -- a proof
/// reveals only the statement it proves, and saying so is the whole reason this
/// screen exists on a transport that would otherwise just background the app.
enum DisclosureFeedbackType {
  success,
  zeroKnowledge,
  canceled,
  notSatisfiable;

  /// Whether this outcome shows the success graphic rather than the error one.
  bool get isSuccess =>
      this == DisclosureFeedbackType.success ||
      this == DisclosureFeedbackType.zeroKnowledge;
}

class DisclosureFeedbackScreen extends StatefulWidget {
  static const _translationKeys = {
    DisclosureFeedbackType.success: "success",
    DisclosureFeedbackType.zeroKnowledge: "zero_knowledge",
    DisclosureFeedbackType.canceled: "canceled",
    DisclosureFeedbackType.notSatisfiable: "not_satisfiable",
  };

  final DisclosureFeedbackType feedbackType;
  final String otherParty;
  final Function(BuildContext) onDismiss;
  final bool isSignatureSession;

  /// How long the wallet worked after the user agreed. Shown only for a
  /// zero-knowledge disclosure, where it is the one number worth naming: the
  /// user waited seconds for it, and saying how long turns a wallet that felt
  /// slow into one that did visible work. Null when nothing measured it, which
  /// drops the sentence rather than printing a zero.
  final Duration? duration;

  final String? _translationKey;

  DisclosureFeedbackScreen({
    required this.feedbackType,
    required this.otherParty,
    required this.onDismiss,
    this.duration,
    bool? isSignatureSession,
  }) : isSignatureSession = isSignatureSession ?? false,
       _translationKey = _translationKeys[feedbackType];

  @override
  State<StatefulWidget> createState() {
    return DisclosureFeedbackScreenState();
  }
}

class DisclosureFeedbackScreenState extends State<DisclosureFeedbackScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final otherPartyTranslationParam = {"otherParty": widget.otherParty};

    // The timing sentence is a separate key rather than an empty parameter in
    // the same one: a wallet that did not measure the disclosure must not print
    // "took  seconds" with a hole in it, and the sentence has to read naturally
    // in every locale, which a blank substitution does not.
    final isZeroKnowledge =
        widget.feedbackType == DisclosureFeedbackType.zeroKnowledge;
    final timed = isZeroKnowledge && widget.duration != null;
    final explanationParams = timed
        ? {
            ...otherPartyTranslationParam,
            "duration": _formatDuration(context, widget.duration!),
          }
        : otherPartyTranslationParam;

    return ActionFeedback(
      success: widget.feedbackType.isSuccess,
      // The zero-knowledge headline is the message, not a status line: what
      // matters is not that the disclosure worked but that nothing was handed
      // over. It gets the larger size so it lands before the explanation.
      prominentTitle:
          widget.feedbackType == DisclosureFeedbackType.zeroKnowledge,
      titleTranslationKey:
          "disclosure.feedback.header.${widget._translationKey}",
      titleTranslationParams: otherPartyTranslationParam,
      // The zero-knowledge explanation is markdown: it puts the requestor on its
      // own line and in bold. TranslatedText renders markdown only for a key
      // whose last segment carries _markdown, so the suffix is what selects it
      // and every other outcome stays plain text.
      explanationTranslationKey:
          "disclosure.feedback.text.${widget._translationKey}"
          "${widget.isSignatureSession ? "_signature" : ""}"
          "${isZeroKnowledge ? "_markdown" : ""}"
          "${timed ? "_timed" : ""}",
      explanationTranslationParams: explanationParams,
      onDismiss: () => widget.onDismiss(context),
    );
  }

  /// Seconds to three decimals, in the reader's own locale: a Dutch reader gets
  /// "1,188" where an English one gets "1.188".
  ///
  /// Three decimals rather than one because the wallet already measures in whole
  /// milliseconds and there is no reason to throw that away on the way to the
  /// screen. Three consecutive runs of the same circuit came back 1188, 1077 and
  /// 1201 ms — a real spread that one decimal flattens to "1.2, 1.1, 1.2".
  ///
  /// Still expressed in SECONDS rather than as "1188 ms": the unit word lives in
  /// the locale strings ("seconds" / "seconden" / "Sekunden"), so switching to
  /// milliseconds means rewriting that sentence in three languages for no gain.
  /// The resolution is identical either way.
  String _formatDuration(BuildContext context, Duration duration) {
    final locale = Localizations.localeOf(context).toString();
    return NumberFormat("0.000", locale).format(duration.inMilliseconds / 1000);
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    // If the app is resumed remove the route with this screen from the stack.
    if (state == AppLifecycleState.resumed) {
      widget.onDismiss(context);
    }
  }
}
