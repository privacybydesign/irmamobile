import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:irmamobile/src/util/translated_text.dart';
import 'package:irmamobile/src/widgets/action_feedback.dart';

enum DisclosureFeedbackType {
  success,
  canceled,
  notSatisfiable,
}

class DisclosureFeedbackScreen extends StatefulWidget {
  static const _translationKeys = {
    DisclosureFeedbackType.success: "success",
    DisclosureFeedbackType.canceled: "canceled",
    DisclosureFeedbackType.notSatisfiable: "notSatisfiable",
  };

  final DisclosureFeedbackType feedbackType;
  final String otherParty;
  final Function(BuildContext) popToWallet;

  final String _translationKey;

  DisclosureFeedbackScreen({this.feedbackType, this.otherParty, this.popToWallet, Key key})
      : _translationKey = _translationKeys[feedbackType],
        super(key: key);

  @override
  State<StatefulWidget> createState() {
    return DisclosureFeedbackScreenState();
  }
}

class DisclosureFeedbackScreenState extends State<DisclosureFeedbackScreen> with WidgetsBindingObserver {
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
    return ActionFeedback(
      success: widget.feedbackType == DisclosureFeedbackType.success,
      title: TranslatedText(
        "disclosure.feedback.header.${widget._translationKey}",
        translationParams: {"otherParty": widget.otherParty},
        style: Theme.of(context).textTheme.display3,
      ),
      explanation: TranslatedText(
        "disclosure.feedback.text.${widget._translationKey}",
        translationParams: {"otherParty": widget.otherParty},
        textAlign: TextAlign.center,
      ),
      onDismiss: () => widget.popToWallet(context),
    );
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    // If the app is resumed remove the route with this screen from the stack.
    if (state == AppLifecycleState.resumed) {
      widget.popToWallet(context);
    }
  }
}
