import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/session_state.dart";
import "../../../theme/yivi_palette.dart";
import "../../../widgets/action_feedback.dart";
import "../../../widgets/credential_card/disclosed_card_tile.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_bottom_bar_base.dart";
import "../../../widgets/translated_text.dart";
import "../../../widgets/yivi_themed_button.dart";
import "session_columns.dart";
import "session_scaffold.dart";
import "success_graphic.dart";

enum DisclosureFeedbackType { success, canceled, notSatisfiable }

class DisclosureFeedbackScreen extends StatefulWidget {
  static const _translationKeys = {
    DisclosureFeedbackType.success: "success",
    DisclosureFeedbackType.canceled: "canceled",
    DisclosureFeedbackType.notSatisfiable: "not_satisfiable",
  };

  final DisclosureFeedbackType feedbackType;
  final String otherParty;
  final Function(BuildContext) onDismiss;
  final bool isSignatureSession;

  /// The cards (with only the shared attributes) the user just shared,
  /// listed under "What you shared" on success.
  final List<SelectableCredentialInstance> shared;

  final String? _translationKey;

  DisclosureFeedbackScreen({
    required this.feedbackType,
    required this.otherParty,
    required this.onDismiss,
    bool? isSignatureSession,
    this.shared = const [],
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
    final explanationKey =
        'disclosure.feedback.text.${widget._translationKey}${widget.isSignatureSession ? '_signature' : ''}';

    if (widget.feedbackType == DisclosureFeedbackType.success &&
        widget.shared.isNotEmpty) {
      return _buildSuccessWithShared(
        context,
        otherPartyTranslationParam,
        explanationKey,
      );
    }

    return ActionFeedback(
      success: widget.feedbackType == DisclosureFeedbackType.success,
      titleTranslationKey:
          "disclosure.feedback.header.${widget._translationKey}",
      titleTranslationParams: otherPartyTranslationParam,
      explanationTranslationKey: explanationKey,
      explanationTranslationParams: otherPartyTranslationParam,
      onDismiss: () => widget.onDismiss(context),
    );
  }

  /// The success feedback followed by the cards the user shared.
  Widget _buildSuccessWithShared(
    BuildContext context,
    Map<String, String> params,
    String explanationKey,
  ) {
    final palette = YiviPalette.of(context);
    final okButton = YiviThemedButton(
      key: const Key("ok_button"),
      label: "action_feedback.ok",
      onPressed: () => widget.onDismiss(context),
    );
    final whatYouShared = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Semantics(
          header: true,
          child: TranslatedText(
            "disclosure.what_you_shared",
            style: palette.display(16),
          ),
        ),
      ),
      for (final instance in widget.shared)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: DisclosedCardTile(instance: instance),
        ),
    ];

    // Tablets: the result and OK on the left, what was shared on the right.
    if (useSessionColumns(context)) {
      return PopScope(
        canPop: false,
        child: SessionScaffold(
          appBarTitle: "disclosure.feedback.header.success",
          onDismiss: () => widget.onDismiss(context),
          wide: true,
          scrollsUnderBars: true,
          body: SessionColumns(
            startWidth: 380,
            endWidth: 440,
            gap: 96,
            centreVertically: true,
            start: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 120,
                  width: 120,
                  child: SuccessGraphic(),
                ),
                const SizedBox(height: 32),
                TranslatedText(
                  "disclosure.feedback.header.success",
                  translationParams: params,
                  isHeader: true,
                  style: palette
                      .display(34, weight: FontWeight.w700)
                      .copyWith(height: 44 / 34, color: palette.heading),
                ),
                const SizedBox(height: 8),
                TranslatedText(
                  explanationKey,
                  translationParams: params,
                  style: palette.body(18).copyWith(height: 28 / 18),
                ),
                const SizedBox(height: 32),
                okButton,
              ],
            ),
            end: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: whatYouShared,
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      child: SessionScaffold(
        appBarTitle: "disclosure.feedback.header.success",
        onDismiss: () => widget.onDismiss(context),
        scrollsUnderBars: true,
        body: BarInsetsBuilder(
          builder: (context, insets) => ListView(
            padding: insets + const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              const SizedBox(height: 160, child: SuccessGraphic()),
              const SizedBox(height: 16),
              TranslatedText(
                "disclosure.feedback.header.success",
                translationParams: params,
                style: palette.display(26, weight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              TranslatedText(
                explanationKey,
                translationParams: params,
                style: palette.body(16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ...whatYouShared,
            ],
          ),
        ),
        bottomNavigationBar: IrmaBottomBarBase(child: okButton),
      ),
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
