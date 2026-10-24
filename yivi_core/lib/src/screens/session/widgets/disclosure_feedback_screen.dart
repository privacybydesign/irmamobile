import "package:collection/collection.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/session_state.dart";
import "../../../theme/yivi_corners.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/i18n.dart";
import "../../../widgets/action_feedback.dart";
import "../../../widgets/done_check.dart";
import "../../../widgets/glass/pill_buttons.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_bottom_bar_base.dart";
import "../models/disclosure_view_model.dart";
import "issuance_permission.dart";
import "session_columns.dart";
import "session_scaffold.dart";
import "shared_card_tile.dart";

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

  /// The session continues on another device (the one that showed the QR
  /// code).
  final bool onOtherDevice;

  final String? _translationKey;

  DisclosureFeedbackScreen({
    required this.feedbackType,
    required this.otherParty,
    required this.onDismiss,
    bool? isSignatureSession,
    this.shared = const [],
    this.onOtherDevice = false,
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

    if (widget.feedbackType == DisclosureFeedbackType.success) {
      return _buildShared(context);
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

  /// "Shared with {requestor}": a check, what was shared, and a note when
  /// that was a card's last use.
  Widget _buildShared(BuildContext context) {
    final palette = YiviPalette.of(context);
    final lang = FlutterI18n.currentLocale(context)?.languageCode;
    final requestor = {"requestor": widget.otherParty};
    final shared = widget.shared;

    final title = shared.isEmpty
        ? context.tr("share.done.title_none")
        : widget.isSignatureSession
        ? context.tr("share.done.title_signature")
        : context.tr("share.done.title", requestor);
    final text = shared.isEmpty
        ? context.tr("share.done.text_none", requestor)
        : widget.onOtherDevice
        ? context.tr("share.done.text_second_device", requestor)
        : context.tr("share.done.text", requestor);
    final lastUse = shared.firstWhereOrNull(isLastUse);

    final heading = <Widget>[
      const Center(child: DoneCheck(key: Key("share_done_check"), size: 84)),
      const SizedBox(height: 12),
      Semantics(
        header: true,
        child: Text(
          title,
          key: const Key("share_done_title"),
          textAlign: TextAlign.center,
          style: palette.display(25).copyWith(color: palette.text),
        ),
      ),
      const SizedBox(height: 12),
      Text(
        text,
        textAlign: TextAlign.center,
        style: palette
            .body(15)
            .copyWith(height: 22 / 15, color: palette.heading),
      ),
    ];
    final details = <Widget>[
      for (final instance in shared)
        SharedCardTile(
          bundle: DisclosureBundle(credentials: [instance]),
          showStatus: false,
        ),
      if (lastUse != null)
        Container(
          key: const Key("share_done_last_use"),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: ShapeDecoration(
            color: palette.warningSurface,
            shape: const RoundedRectangleBorder(
              borderRadius: YiviCorners.cardRadius,
            ),
          ),
          child: Text(
            context.tr("share.done.last_use", {
              "name": inSentence(lastUse.name, language: lang),
            }),
            style: palette
                .body(14)
                .copyWith(height: 20 / 14, color: palette.warningText),
          ),
        ),
    ];
    final button = FancyPillButton(
      key: const Key("ok_button"),
      label: FlutterI18n.translate(context, "share.done.button"),
      onPressed: () => widget.onDismiss(context),
    );

    // A phone held sideways, as the issuance success: the check and the
    // button in the panel at the left, the words and what was shared at the
    // right, scrolling the full height.
    if (!useSessionColumns(context) && useSheetColumns(context)) {
      return PopScope(
        canPop: false,
        child: SessionScaffold(
          appBarTitle: "disclosure.feedback.header.success",
          onDismiss: () => widget.onDismiss(context),
          wide: true,
          scrollsUnderBars: true,
          cornerClose: true,
          body: IssuanceLandscape(
            key: const Key("share_done_landscape"),
            title: title,
            note: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                text,
                style: palette
                    .body(15)
                    .copyWith(height: 22 / 15, color: palette.heading),
              ),
            ),
            overview: const [
              Center(child: DoneCheck(key: Key("share_done_check"), size: 84)),
            ],
            receives: [
              for (final (n, d) in details.indexed) ...[
                if (n > 0) const SizedBox(height: 12),
                d,
              ],
            ],
            actions: FancyPillButton(
              key: const Key("ok_button"),
              label: FlutterI18n.translate(context, "share.done.button"),
              size: PillSize.regular,
              onPressed: () => widget.onDismiss(context),
            ),
          ),
        ),
      );
    }

    // Tablets: the result and the button on the left, what was shared on
    // the right.
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [...heading, const SizedBox(height: 32), button],
            ),
            end: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: details,
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
            padding: insets + const EdgeInsets.fromLTRB(16, 24, 16, 24),
            children: [
              ...heading,
              for (final d in details) ...[const SizedBox(height: 16), d],
            ],
          ),
        ),
        bottomNavigationBar: IrmaBottomBarBase(child: button),
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
