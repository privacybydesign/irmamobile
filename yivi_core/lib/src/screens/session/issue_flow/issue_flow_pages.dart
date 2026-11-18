import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/credential.dart";
import "../../../models/credential_store.dart";
import "../../../models/session_state.dart";
import "../../../providers/credential_store_provider.dart";
import "../../../providers/session_flow_provider.dart";
import "../../../providers/session_state_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_space.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/i18n.dart";
import "../../../widgets/buttons/pill_buttons.dart";
import "../../../widgets/feedback/spinner.dart";
import "../../../widgets/sheet/sheet.dart";
import "../../../widgets/sheet/sheet_actions.dart";
import "../../../widgets/sheet/sheet_layout.dart";
import "../../add_data/add_data_details_content.dart";
import "../../embedded_issuance_flows/documents/document_sheet_step.dart";
import "../../embedded_issuance_flows/widgets/contact_sheet_step.dart";
import "../issuance/issuance_permission.dart";
import "../issuance/issue_sheet_progress.dart";
import "../issuance/issue_website_step.dart";
import "../issuance/openid4vci_preauth_txcode_screen.dart";
import "../issuance/received_card_tile.dart";
import "../models/disclosure_view_model.dart";
import "../models/issuance_view_model.dart";
import "../models/session_view.dart";
import "../models/technical_details.dart";
import "../requestor/requestor_card.dart";
import "../requestor/requestor_trust_sheet.dart";
import "../requestor/technical_details_sheet.dart";
import "../result/issuance_success_screen.dart";
import "../session_pin_entry_screen.dart";
import "issue_flow_controller.dart";
import "issue_sheet.dart";

/// The pages of [flow], one or two per step of its stack, bottom first, to
/// follow the sheet's own pages in its [SheetPages]; none while on the
/// sheet's root page. Called while the sheet builds: what the pages show
/// is read here, so a page sliding out stays as it was.
List<Widget> issueFlowPages(IssueSheetFlow flow) {
  final s = flow.now;
  final ref = flow.ref;
  final adding = s.adding;
  final nested = s.sessionId;
  // A session taken without a type picked first has no steps before its
  // issuance: no progress, and the requestor as the subject.
  if (adding == null && !(s.standalone && s.hasSession)) return const [];
  final IssueSheetSubject? subject;
  final int total;
  if (adding != null) {
    subject = flow.host.subject(adding);
    total = flow.stepsOf(adding);
  } else {
    final requestor = nested == null
        ? null
        : ref.watch(sessionStateProvider(nested)).value?.requestor;
    subject = requestor == null ? null : IssueSheetSubject.request(requestor);
    total = 0;
  }
  final offer = s.lastOffer;
  final offered = offer?.offeredCredentials;
  final issuer = offered == null || offered.isEmpty
      ? null
      : offered.first.issuer;

  List<Widget> pagesOf(IssueStep step) => switch (step) {
    DetailsStep(:final d) => [
      KeyedSubtree(
        key: ValueKey(("add", d.credentialId)),
        child: IssueDetailsPage(
          flow: flow,
          d: d,
          subject: subject!,
          total: total,
          faq: _faqFor(ref, d.credentialId),
          direct: s.direct,
        ),
      ),
    ],
    // The issuer's page, from the ⓘ on the details' issuer card.
    DetailsIssuerStep() => [
      KeyedSubtree(
        key: ValueKey(("details_issuer", adding!.credentialId)),
        child: RequestorTrustSheet(
          key: const Key("details_issuer_page"),
          requestor: adding.issuer,
          issuer: true,
          logoKey: flow.keys.detailsLogoTo,
          onBack: () => flow.closeDetailsIssuer(adding.issuer),
        ),
      ),
    ],
    // Step 2 for a card from a website: where you go, and the way there.
    WebsiteStep(:final opened) => [
      KeyedSubtree(
        key: ValueKey(("web", adding!.credentialId)),
        child: IssueWebsiteStep(
          title: adding.name,
          host: hostOf(adding.issueURL) ?? adding.issuer.name,
          issuer: adding.issuer.name,
          opened: opened,
          onOpen: () => flow.openWebsite(adding),
          onBack: flow.leaveWebsite,
          bottom: IssueSheetProgress(step: 2, total: total),
          titleWidget: IssueRequestorPill.maybe(subject),
          onOther: flow.host.hasOtherChoices ? flow.chooseOther : null,
        ),
      ),
    ],
    ContactStep(flow: final contact) => [
      KeyedSubtree(
        key: ValueKey(("prove", contact)),
        child: ContactSheetStep(
          flow: contact,
          subject: subject!,
          total: total,
          onBack: flow.controller.leaveContact,
        ),
      ),
      // Once the code is sent, its page slides in over the address.
      if (ContactSheetStep.atCode(ref, contact))
        KeyedSubtree(
          key: ValueKey(("code", contact)),
          child: ContactSheetStep(
            flow: contact,
            subject: subject,
            total: total,
            code: true,
            onBack: flow.controller.leaveContact,
          ),
        ),
    ],
    DocumentStepPage(:final type) => [
      KeyedSubtree(
        key: ValueKey(("document", type)),
        // A sheet page itself: its bar and progress stay while the
        // document's screens change below them.
        child: DocumentSheetStep(
          type: type,
          subject: subject!,
          onBack: flow.controller.leaveDocument,
        ),
      ),
    ],
    IssueSessionStep(:final sessionId) => [
      KeyedSubtree(
        key: ValueKey(("issue", sessionId)),
        child: _issuancePage(flow, sessionId, subject, total),
      ),
    ],
    // The issuer's details, from the trust label on the question (back
    // returns to the question), and their technical details over them.
    IssuerStep(technical: false) when issuer != null => [
      KeyedSubtree(
        key: ValueKey(("issuer", nested)),
        child: RequestorTrustSheet(
          key: const Key("issuer_trust_page"),
          requestor: issuer,
          issuer: true,
          logoKey: flow.keys.issuerLogoTo,
          onBack: () => flow.closeIssuerPage(issuer),
          onTechnicalDetails: () => flow.controller.openIssuer(technical: true),
        ),
      ),
    ],
    IssuerStep(technical: true) when issuer != null => [
      KeyedSubtree(
        key: ValueKey(("issuer_tech", nested)),
        child: TechnicalDetailsSheet(
          key: const Key("issuer_technical_details"),
          groups: issuanceTechnicalDetailsOf(offer!, offered!, flow.context.tr),
          onBack: () => flow.controller.closeIssuer(technical: true),
        ),
      ),
    ],
    IssuerStep() => const [],
    // The PIN while irmago asks for it; it stays under "Success" once
    // shown, so "Success" comes in over it.
    PinStep(:final sessionId) => [
      KeyedSubtree(
        key: ValueKey(("pin", sessionId)),
        child: IssuePinPage(
          sessionId: sessionId,
          subject: subject,
          total: total,
          onCancel: flow.controller.dismissSession,
        ),
      ),
    ],
    // "Success", a page of its own, coming in forward over the offer (or
    // the PIN).
    SuccessStep(:final cards) => [
      KeyedSubtree(
        key: ValueKey(("done", nested)),
        child: IssueSuccessPage(flow: flow, cards: cards, subject: subject),
      ),
    ],
  };

  return [for (final step in s.stack) ...pagesOf(step)];
}

Faq? _faqFor(WidgetRef ref, String credentialId) {
  final store = ref.watch(groupedCredentialStoreProvider).value;
  for (final group in store ?? const <CredentialStoreCategory>[]) {
    for (final item in group.items) {
      if (item.credential.credentialId == credentialId) return item.faq;
    }
  }
  return null;
}

/// Step 3: the issuance that came back (the offer, or OpenID4VCI's own
/// step before it), then "Success".
Widget _issuancePage(
  IssueSheetFlow flow,
  int sessionId,
  IssueSheetSubject? subject,
  int total,
) {
  final ref = flow.ref;
  final view = ref.watch(sessionFlowProvider(sessionId));
  if (_openIdStepOf(view) case final step?) {
    return IssueOpenIdPage(
      flow: flow,
      step: step,
      sessionId: sessionId,
      opened: flow.now.authOpened.contains(sessionId),
    );
  }
  return IssueOfferPage(
    flow: flow,
    sessionId: sessionId,
    subject: subject,
    total: total,
    view: view,
    awaiting: ref.watch(sessionAwaitingInteractionProvider(sessionId)),
    state: flow.now,
  );
}

/// OpenID4VCI's own step before the offer in [view], if it is one: a
/// transaction code, the issuer's website for the authorization code, or
/// the wait while a pre-authorized code without a transaction code is
/// granted. While a tap waits for Go's answer the step stays.
SessionView? _openIdStepOf(SessionView? view) {
  final step = switch (view) {
    SessionWaiting(:final state?) => sessionViewOf(state, awaiting: false),
    _ => view,
  };
  return switch (step) {
    SessionTxCode() || SessionAuthCode() => step,
    SessionWaiting(:final state?)
        when state.status == SessionStatus.requestPreAuthorizedCode =>
      step,
    _ => null,
  };
}

/// A page still waiting for the issuance's next state.
Widget _loading() => Padding(
  padding: const EdgeInsets.symmetric(vertical: 80),
  child: Center(child: Spinner()),
);

/// Step 1: what the card is, as on the add-data page. It stays under the
/// pages of step 2, which go back to it.
class IssueDetailsPage extends StatelessWidget {
  final IssueSheetFlow flow;
  final CredentialDescriptor d;
  final IssueSheetSubject subject;
  final int total;
  final Faq? faq;

  /// The sheet opened on these details: they are its first page, with its
  /// close button as the way out instead of back.
  final bool direct;

  const IssueDetailsPage({
    super.key,
    required this.flow,
    required this.d,
    required this.subject,
    required this.total,
    required this.faq,
    required this.direct,
  });

  @override
  Widget build(BuildContext context) {
    final keys = flow.keys;
    // One way on: dragging the sheet down and back are the way out.
    final action = SheetAction(
      key: const Key("sheet_go_button"),
      label: context.tr("data.add.details.get_button"),
      onTap: () => flow.add(d),
    );
    final howIntro = switch (flow.planOf(d).howIntroKey) {
      final key? => context.tr(key),
      null => null,
    };
    Widget part(AddDataDetailsPart part) => AddDataDetailsContent(
      credential: d,
      faq: faq,
      heroKey: keys.hero,
      titleKey: keys.title("details"),
      howIntro: howIntro,
      part: part,
      onIssuer: () => flow.openDetailsIssuer(d.issuer),
      issuerLogoKey: keys.detailsLogoFrom,
    );
    // "Add {name}" names the page; the card's name is its heading, and the
    // bar shows the title only once that has scrolled away.
    final title = SheetTitle(
      context.tr("data.add.details.title_add", {"name": d.name}),
      widget: IssueRequestorPill.maybe(subject),
      centred: true,
      reveal: SheetTitleReveal.under(keys.title("details")),
    );
    // The sheet's first page has no back: its close button is the way out,
    // where back is on the pages after it. Otherwise left by back or by
    // dragging its header down.
    final exits = SheetExits(
      onBack: direct ? null : flow.leave,
      close: direct ? SheetClose.start : SheetClose.none,
    );
    final bottom = IssueSheetProgress(step: 1, total: total);
    // A phone held sideways: the card, its name and the intro at the left,
    // what you get at the right; the way on is in the bar.
    if (useSheetColumns(context)) {
      return SheetPage.split(
        title: title,
        exits: exits,
        action: action,
        bottomInBar: true,
        bottom: bottom,
        child: SheetSplit(
          start: [part(AddDataDetailsPart.card)],
          end: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: YiviSpace.x12,
            children: [part(AddDataDetailsPart.rest)],
          ),
        ),
      );
    }
    return SheetPage.scroll(
      title: title,
      exits: exits,
      padding: const EdgeInsets.symmetric(horizontal: YiviSpace.x16),
      action: action,
      bottom: bottom,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: YiviSpace.x16,
        children: [part(AddDataDetailsPart.all)],
      ),
    );
  }
}

/// Step 3: "Do you want to add this data?", the issuance's offer. After
/// "Add", and under "Success" (sliding away as it comes in), the offer as
/// it was: the session has moved on by then.
class IssueOfferPage extends StatelessWidget {
  final IssueSheetFlow flow;
  final int sessionId;
  final IssueSheetSubject? subject;
  final int total;

  /// What the session shows now.
  final SessionView view;

  /// A tap waits for Go's answer.
  final bool awaiting;

  /// The flow as the page was built.
  final IssueFlowState state;

  const IssueOfferPage({
    super.key,
    required this.flow,
    required this.sessionId,
    required this.subject,
    required this.total,
    required this.view,
    required this.awaiting,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final keys = flow.keys;
    final current = view is SessionOffer ? view.state : null;
    final offer =
        current ??
        (state.added != null || state.granted ? state.lastOffer : null);
    final cards = offer?.offeredCredentials ?? const <Credential>[];

    // Inside a request, a card whose value is not what the request needs
    // does not count: trying again comes first, adding it anyway second.
    // Nobody vouches for the issuer: adding becomes "Add anyway", neutral,
    // with the reason above it and a red wash at the top, as sharing with a
    // requestor nobody vouches for.
    final offerState = issuanceOfferOf(
      cards,
      forRequest: flow.host.request,
      retryOnMismatch: true,
    );
    final grant = offer == null ? null : flow.controller.grant;
    final issuer = offerState.issuer;
    final risky = offerState.risky;
    final action = switch (offerState.primary) {
      IssuancePrimary.retry || IssuancePrimary.dontReplace => SheetAction(
        key: const Key("sheet_issue_retry"),
        label: context.tr(
          offerState.primary == IssuancePrimary.dontReplace
              ? "share.offer.dont_replace"
              : "share.offer.retry",
        ),
        onTap: offerState.primary == IssuancePrimary.dontReplace
            ? flow.close
            : flow.controller.retry,
      ),
      IssuancePrimary.add || IssuancePrimary.addAnyway => SheetAction(
        key: const Key("sheet_issue_add"),
        label: risky
            ? context.tr("issuance.question.add_anyway")
            : issuanceAddLabel(context, cards.length),
        neutral: risky,
        // Under way once tapped, until "Success" comes in.
        busy: awaiting,
        onTap: grant,
      ),
    };
    final anyway = switch (offerState.link) {
      final link? => Center(
        child: TextLink(
          key: const Key("sheet_issue_add"),
          label: context.tr(switch (link) {
            IssuanceLink.replaceAnyway => "share.offer.replace_anyway",
            IssuanceLink.addAnyway => "share.offer.add_anyway",
          }),
          onPressed: awaiting ? null : grant,
        ),
      ),
      null => null,
    };
    final sideways = useSheetColumns(context);
    // Above the button: why it says "anyway" for an issuer nobody vouches
    // for (no progress then: it is the last step anyway); else the progress.
    final bottom = risky
        ? IssuanceRiskyReason(
            issuer: issuer!,
            textAlign: sideways ? TextAlign.start : TextAlign.center,
          )
        : IssueSheetProgress.lastStep(total);
    final content = offer == null ? null : offerState;
    final question = issuer == null
        ? null
        : issuanceHeading(
            context,
            issuer: issuer,
            count: cards.length,
            titleKey: keys.title("issuance"),
            logoKey: keys.issuerLogoFrom,
            cardKey: keys.issuerCard,
            onTrust: () => flow.openIssuerPage(issuer),
          );
    final loading = _loading();
    // The cards: their values in tiles, the mismatch note above them.
    List<Widget> cardsAndValues(IssuanceOfferState content) => [
      const YouGetLabel(),
      ?IssuanceMismatchNote.maybe(content),
      ...receivedCardTiles(context, content),
      ?anyway,
    ];
    // The question is the page's heading; the bar names the page once that
    // has scrolled away. The issuer sticks under the bar once their card
    // has (the "For" pill stays in the bar).
    final title = SheetTitle(
      context.tr("issuance.title"),
      widget: IssueRequestorPill.maybe(subject),
      centred: true,
      reveal: SheetTitleReveal.under(keys.title("issuance")),
    );
    // Back declines this issuance: on the details again, to try again.
    final exits = SheetExits(onBack: flow.back);
    final page = sideways
        ? SheetPage.split(
            title: title,
            exits: exits,
            action: action,
            // The progress in the bar sideways; the reason stays with the
            // button.
            bottomInBar: !risky,
            bottom: bottom,
            // A phone held sideways: the issuer and the question at the left
            // with the button under them; the cards at the right.
            child: SheetSplit(
              key: content == null ? null : const Key("sheet_issuance"),
              start: [?question],
              end: content == null
                  ? loading
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: YiviSpace.x8,
                      children: cardsAndValues(content),
                    ),
            ),
          )
        : SheetPage.scroll(
            title: title,
            exits: exits,
            padding: const EdgeInsets.symmetric(horizontal: YiviSpace.x16),
            action: action,
            bottom: bottom,
            underBar: issuer == null
                ? null
                : (
                    row: RequestorCompactBar(
                      requestor: issuer,
                      subtitle: cards.length > 1
                          ? context.tr("issuance.bar_subtitle.many", {
                              "count": "${cards.length}",
                            })
                          : context.tr("issuance.bar_subtitle.one"),
                    ),
                    after: keys.issuerCard,
                  ),
            child: content == null || question == null
                ? loading
                : KeyedSubtree(
                    key: const Key("sheet_issuance"),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [question, ...cardsAndValues(content)],
                    ),
                  ),
          );
    return IssuanceTrustWash(on: risky, child: page);
  }
}

/// OpenID4VCI's transaction code or authorization-code step ([step]), as a
/// page; or the wait while a pre-authorized code is granted. Back declines
/// the issuance.
class IssueOpenIdPage extends ConsumerWidget {
  final IssueSheetFlow flow;
  final SessionView step;
  final int sessionId;

  /// The issuer's login page in the browser was opened.
  final bool opened;

  const IssueOpenIdPage({
    super.key,
    required this.flow,
    required this.step,
    required this.sessionId,
    required this.opened,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (step) {
      case SessionTxCode(:final state, :final parameters):
        return OpenID4VCIPreAuthTxCodeScreen(
          inSheet: true,
          sessionId: sessionId,
          issuedCredentials: state.offeredCredentialTypes ?? const [],
          transactionCodeParameters: parameters,
          onSubmit: ref
              .read(sessionFlowProvider(sessionId).notifier)
              .grantPreAuthorizedCode,
          onDismiss: flow.controller.dismissSession,
        );
      case SessionAuthCode(:final state, :final url):
        // The issuer's login in the browser: the website page of adding a
        // card, as for a card from a website.
        return IssueWebsiteStep(
          key: const Key("sheet_openid4vci_authcode"),
          title: context.tr("issuance.authorization_code.pending.title"),
          host: hostOf(url) ?? state.requestor.name,
          issuer: state.requestor.name,
          opened: opened,
          onOpen: () => flow.controller.openAuthorization(sessionId, url),
          onBack: flow.controller.dismissSession,
        );
      default:
        // Granted at once (by the session's flow); the next state follows.
        return SheetPage.scroll(
          title: SheetTitle(context.tr("issuance.title")),
          // Left by dragging its header down: no close button.
          exits: SheetExits(
            onBack: flow.controller.dismissSession,
            close: SheetClose.none,
          ),
          child: _loading(),
        );
    }
  }
}

/// The PIN for the issuance in the sheet, as a page of the sheet: the PIN
/// pad without the logo, under the sheet's bar and the progress.
class IssuePinPage extends StatelessWidget {
  final int sessionId;
  final IssueSheetSubject? subject;

  /// The flow's number of steps; the PIN is part of the last (adding it).
  /// 0: an issuance without steps before it, and no progress.
  final int total;
  final VoidCallback onCancel;

  const IssuePinPage({
    super.key,
    required this.sessionId,
    required this.subject,
    required this.total,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    // The pad fills the page and scales itself to it; it does not scroll.
    // It keeps clear of the home indicator itself (YiviPinScreen), so the
    // link under the keypad sits as low as on the full-screen PIN.
    return SheetPage.fill(
      title: SheetTitle(
        context.tr("issuance.title"),
        widget: IssueRequestorPill.maybe(subject),
        centred: true,
      ),
      // Left by dragging its header down: no close button.
      exits: SheetExits(onBack: onCancel, close: SheetClose.none),
      padding: const EdgeInsets.symmetric(horizontal: YiviSpace.x16),
      child: SessionPinPage(
        key: const Key("sheet_pin"),
        sessionId: sessionId,
        inSheet: true,
        onCancel: onCancel,
      ),
    );
  }
}

/// "Success": the added [cards], with the host's words and its way on.
class IssueSuccessPage extends StatelessWidget {
  final IssueSheetFlow flow;
  final List<Credential> cards;
  final IssueSheetSubject? subject;

  const IssueSuccessPage({
    super.key,
    required this.flow,
    required this.cards,
    required this.subject,
  });

  /// The added card's width on "Success".
  static const double _receivedWidth = 298;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final host = flow.host;
    final keys = flow.keys;
    final action = host.successAction(cards);
    final link = host.successLink?.call(cards);
    final linkText = link == null
        ? null
        : TextLink(key: link.key, label: link.label, onPressed: link.onTap);
    final sideways = useSheetColumns(context);
    final linkButton = linkText == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(top: YiviSpace.x8),
            // Under the words they go with: centred upright, at the start
            // of the column sideways.
            child: sideways
                ? Align(
                    alignment: AlignmentDirectional.centerStart,
                    // Its words flush with the text above (the link pads
                    // its tap area by 8).
                    child: Transform.translate(
                      offset: Offset(
                        Directionality.of(context) == TextDirection.rtl
                            ? 8
                            : -8,
                        0,
                      ),
                      child: linkText,
                    ),
                  )
                : Center(child: linkText),
          );
    // "Success" is the page's heading; the bar names it only once that has
    // scrolled away. Done: no progress; the way on is the way out.
    final received = Center(
      child: SizedBox(
        // The card at about four fifths of the page's width (the success
        // picture is the card minus 48 of room for its check).
        width: _receivedWidth + 48,
        child: IssuanceReceived(cards: cards, cardKeys: keys.added(cards)),
      ),
    );
    final heading = Semantics(
      header: true,
      child: Text(
        context.tr("issuance.success_feedback.header"),
        key: keys.title("done"),
        style: palette.titleStep.copyWith(color: palette.text),
      ),
    );
    final text = Text(
      host.successText(cards),
      key: const Key("sheet_added_text"),
      style: palette.body(16).copyWith(height: 24 / 16),
    );
    final title = SheetTitle(
      context.tr("issuance.success_feedback.header"),
      widget: IssueRequestorPill.maybe(subject),
      centred: true,
      reveal: SheetTitleReveal.under(keys.title("done")),
    );
    // A phone held sideways: "Success", the words and the way on at the
    // left; the card with its check at the right.
    if (sideways) {
      return SheetPage.split(
        title: title,
        exits: SheetExits(close: SheetClose.none),
        action: action,
        child: SheetSplit(
          start: [heading, text, ?linkButton],
          end: Column(
            key: const Key("sheet_added_values"),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [if (cards.isNotEmpty) received],
          ),
        ),
      );
    }
    return SheetPage.scroll(
      title: title,
      exits: SheetExits(close: SheetClose.none),
      padding: const EdgeInsets.symmetric(horizontal: YiviSpace.x16),
      action: action,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: YiviSpace.x16,
        children: [
          if (cards.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 90), child: received),
          DefaultTextStyle.merge(
            textAlign: TextAlign.center,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: YiviSpace.x16,
              children: [
                Center(child: heading),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: YiviSpace.x24,
                  ),
                  child: text,
                ),
              ],
            ),
          ),
          ?linkButton,
        ],
      ),
    );
  }
}
