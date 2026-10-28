import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/session_state.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/i18n.dart";
import "../../../widgets/action_feedback.dart";
import "../../../widgets/caps_label.dart";
import "../../../widgets/done_check.dart";
import "../../../widgets/glass/pill_buttons.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_bottom_bar_base.dart";
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

  /// The same phone, with a link back: "Back to {host}" opens it
  /// ([onReturn]).
  final String? returnHost;
  final VoidCallback? onReturn;

  /// The same phone without a link back, on iOS: she goes back herself, with
  /// ◀ at the top left.
  final bool goBackYourself;

  final String? _translationKey;

  DisclosureFeedbackScreen({
    required this.feedbackType,
    required this.otherParty,
    required this.onDismiss,
    bool? isSignatureSession,
    this.shared = const [],
    this.onOtherDevice = false,
    this.returnHost,
    this.onReturn,
    this.goBackYourself = false,
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

  /// "Shared with {requestor}": a check, the title, what to do now (big, at
  /// the top: go on on the other screen, back to the website), and what
  /// they got.
  Widget _buildShared(BuildContext context) {
    final palette = YiviPalette.of(context);
    final requestor = {"requestor": widget.otherParty};
    final shared = widget.shared;
    final host = widget.returnHost;

    final title = shared.isEmpty
        ? context.tr("share.done.title_none")
        : widget.isSignatureSession
        ? context.tr("share.done.title_signature")
        : context.tr("share.done.title", requestor);
    final (nextHead, nextText) = host != null
        ? (
            context.tr("share.done.next.return_head", {"host": host}),
            context.tr("share.done.next.return_text"),
          )
        : widget.goBackYourself
        ? (
            context.tr("share.done.next.back_head"),
            context.tr("share.done.next.back_text"),
          )
        : widget.onOtherDevice
        ? (
            context.tr("share.done.next.other_head"),
            context.tr("share.done.next.other_text"),
          )
        : (null, null);
    final nextBox = nextHead == null
        ? null
        : _NextBox(
            head: nextHead,
            text: nextText!,
            statusBar: widget.goBackYourself,
          );

    final heading = <Widget>[
      const Align(
        alignment: Alignment.centerLeft,
        child: DoneCheck(key: Key("share_done_check"), size: 64),
      ),
      const SizedBox(height: 16),
      Semantics(
        header: true,
        child: Text(
          title,
          key: const Key("share_done_title"),
          style: palette.display(27).copyWith(color: palette.text),
        ),
      ),
      if (nextBox != null) ...[const SizedBox(height: 18), nextBox],
      if (shared.isEmpty) ...[
        const SizedBox(height: 12),
        Text(
          context.tr("share.done.text_none", requestor),
          style: palette
              .body(15)
              .copyWith(height: 22 / 15, color: palette.heading),
        ),
      ],
    ];
    final details = <Widget>[
      if (shared.isNotEmpty)
        CapsLabel(
          context.tr("share.done.they_got", requestor),
          padding: const EdgeInsets.symmetric(horizontal: 6),
        ),
      for (final instance in shared)
        SharedCardTile(
          bundle: DisclosureBundle(credentials: [instance]),
          showStatus: false,
        ),
      if (shared.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            context.tr("share.done.in_activity"),
            style: palette
                .body(13.5)
                .copyWith(height: 19 / 13.5, color: palette.secondaryText),
          ),
        ),
    ];
    final label = host != null
        ? context.tr("share.done.next.return_head", {"host": host})
        : FlutterI18n.translate(context, "share.done.button");
    void done() =>
        host != null ? widget.onReturn?.call() : widget.onDismiss(context);
    final button = FancyPillButton(
      key: const Key("ok_button"),
      label: label,
      onPressed: done,
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
            note:
                nextBox ??
                (shared.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          context.tr("share.done.text_none", requestor),
                          style: palette
                              .body(15)
                              .copyWith(
                                height: 22 / 15,
                                color: palette.heading,
                              ),
                        ),
                      )
                    : const SizedBox.shrink()),
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
              label: label,
              size: PillSize.regular,
              onPressed: done,
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
            padding: insets + const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              ...heading,
              for (final (n, d) in details.indexed) ...[
                SizedBox(height: n == 0 ? 28 : 12),
                d,
              ],
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

/// What to do now, at the top of the done screen: a head and a line, and on
/// iOS without a link back a small status bar with ◀ lit, where she taps to
/// go back. The bar shows no app name: she may have come from a browser,
/// mail or another app.
class _NextBox extends StatelessWidget {
  final String head;
  final String text;
  final bool statusBar;

  const _NextBox({
    required this.head,
    required this.text,
    required this.statusBar,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Container(
      key: const Key("share_done_next"),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: ShapeDecoration(
        color: palette.infoSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 4,
        children: [
          if (statusBar)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ExcludeSemantics(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(8, 3, 8, 3),
                      decoration: ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(7),
                          ),
                          side: BorderSide(color: palette.primary, width: 2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 5,
                        children: [
                          Text(
                            "\u25C0",
                            style: palette
                                .body(12, weight: FontWeight.w700)
                                .copyWith(color: palette.link),
                          ),
                          Container(
                            width: 46,
                            height: 9,
                            decoration: ShapeDecoration(
                              color: palette.link.withValues(alpha: 0.35),
                              shape: const StadiumBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "9:41",
                      style: palette
                          .body(12, weight: FontWeight.w600)
                          .copyWith(color: palette.secondaryText),
                    ),
                  ],
                ),
              ),
            ),
          Text(
            head,
            style: palette
                .display(19, weight: FontWeight.w700)
                .copyWith(height: 25 / 19, color: palette.text),
          ),
          Text(
            text,
            style: palette
                .body(15)
                .copyWith(height: 21 / 15, color: palette.heading),
          ),
        ],
      ),
    );
  }
}
