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

  final String? _translationKey;

  DisclosureFeedbackScreen({
    required this.feedbackType,
    required this.otherParty,
    required this.onDismiss,
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
          "${widget.feedbackType == DisclosureFeedbackType.zeroKnowledge ? "_markdown" : ""}",
      explanationTranslationParams: otherPartyTranslationParam,
      onDismiss: () => widget.onDismiss(context),
    );
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    // If the app is resumed remove the route with this screen from the stack.
    if (state == AppLifecycleState.resumed) {
      widget.onDismiss(context);
    }
  }
}
