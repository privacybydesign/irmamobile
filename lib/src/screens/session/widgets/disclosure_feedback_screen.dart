import 'package:flutter/material.dart';

import '../../../widgets/action_feedback.dart';

enum DisclosureFeedbackType {
  success,
  canceled,
  notSatisfiable,
}

class DisclosureFeedbackScreen extends StatefulWidget {
  static const _translationKeys = {
    DisclosureFeedbackType.success: 'success',
    DisclosureFeedbackType.canceled: 'canceled',
    DisclosureFeedbackType.notSatisfiable: 'notSatisfiable',
  };

  final DisclosureFeedbackType feedbackType;
  final String otherParty;
  final Function(BuildContext) popToWallet;

  final String? _translationKey;

  DisclosureFeedbackScreen({
    required this.feedbackType,
    required this.otherParty,
    required this.popToWallet,
  }) : _translationKey = _translationKeys[feedbackType];

  @override
  State<StatefulWidget> createState() {
    return DisclosureFeedbackScreenState();
  }
}

class DisclosureFeedbackScreenState extends State<DisclosureFeedbackScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance?.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final otherPartyTranslationParam = {'otherParty': widget.otherParty};

    return ActionFeedback(
      success: widget.feedbackType == DisclosureFeedbackType.success,
      titleTranslationKey: 'disclosure.feedback.header.${widget._translationKey}',
      titleTranslationParams: otherPartyTranslationParam,
      explanationTranslationKey: 'disclosure.feedback.text.${widget._translationKey}',
      explanationTranslationParams: otherPartyTranslationParam,
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
