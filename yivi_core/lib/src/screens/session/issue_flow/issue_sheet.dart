import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../data/issuance_launcher.dart";
import "../../../models/credential.dart";
import "../../../models/credential_store.dart";
import "../../../models/session_state.dart";
import "../../../routing/navigation.dart";
import "../../../theme/yivi_motion.dart";
import "../../../util/after_frame.dart";
import "../../../util/i18n.dart";
import "../../../widgets/buttons/pill_buttons.dart";
import "../../../widgets/feedback/dialog.dart";
import "../../../widgets/flight/flight.dart";
import "../../../widgets/sheet/sheet.dart";
import "../../../widgets/sheet/sheet_actions.dart";
import "../../embedded_issuance_flows/documents/document_flow.dart";
import "../../error/session_error_screen.dart";
import "../../error/tx_code_lockout_screen.dart";
import "../../need_help/support_party.dart";
import "../issuance/issue_island.dart";
import "../issuance/issue_sheet_progress.dart";
import "../models/disclosure_plan_view.dart";
import "../models/issuance_view_model.dart";
import "../models/session_view.dart";
import "../requestor/requestor_card.dart";
import "issue_flow_controller.dart";
import "issue_flow_pages.dart";

/// Sends the user to the issuer of a credential type: its website, or the
/// app's own flow for the types Yivi issues itself (e-mail, phone,
/// documents). A provider, so tests can see where the sheet sends the user.
final issuerOpenerProvider =
    Provider<Future<void> Function(CredentialDescriptor descriptor)>(
      (ref) =>
          (d) => ref
              .read(issuanceLauncherProvider)
              .open(d.credentialId, d.issueURL),
    );

/// [name] as it reads inside a sentence in the app's language
/// ([inSentence]).
String inSentenceAt(BuildContext context, String name) =>
    inSentence(name, language: context.lang);

/// A choice on "Success" besides its way on, as a link
/// ([IssueSheetHost.successLink]).
typedef IssueSuccessLink = ({String label, VoidCallback onTap, Key key});

/// "Success" that leads on (securing the app after a card): the added card
/// as one row at the top, then [title], [text] and why ([reasons]), with
/// [action] as the page's way on and [later] as the quiet one
/// ([IssueSheetHost.successOffer]).
typedef IssueSuccessOffer = ({
  String title,
  String text,
  List<(IconData, String)> reasons,
  SheetAction action,
  SheetAction later,
});

/// What differs per sheet that adds a card, and needs the sheet's context:
/// the Change sheet of a request adds a card for that request, Add data and
/// the lock screen's scanner add one on their own
/// ([IssueSheetHost.standalone]). Made in the sheet's build.
final class IssueSheetHost {
  /// The request the card is added for, or null when there is none.
  final SessionState? request;

  /// The tag of the progress while a card is added.
  final IssueSheetSubject Function(CredentialDescriptor d) subject;

  /// The text of "Stop adding {name}?".
  final String Function() stopText;

  /// Called on "Add", before the issuer is contacted.
  final void Function(CredentialDescriptor d)? beforeAdd;

  /// The way on from "Success" (in the bar, or at the bottom of a phone
  /// held upright), for the added cards.
  final SheetAction Function(List<Credential> cards) successAction;

  /// Another choice on "Success" ("Add more", "Later"), as a link under
  /// what is now in the app.
  final IssueSuccessLink? Function(List<Credential> cards)? successLink;

  /// The text under "Success", for the added cards.
  final String Function(List<Credential> cards) successText;

  /// Instead of the usual "Success": an offer to go on with, for the added
  /// cards; null for none.
  final IssueSuccessOffer? Function(List<Credential> cards)? successOffer;

  /// There is something else to choose than the card being added: the
  /// website step then offers "Choose something else".
  final bool hasOtherChoices;

  /// The issuance in the sheet succeeded. True: the host took over;
  /// "Success" is not shown.
  final bool Function(List<Credential> cards)? onSucceeded;

  /// A session taken without a type picked first ended without being
  /// added: declined, dismissed, or an error was closed.
  final VoidCallback? onSessionEnded;

  /// Where a session the sheet can't show is pushed full screen; the
  /// sheet's own context when null. The lock screen's scanner sheet lives
  /// where the router isn't.
  final BuildContext Function()? routeContext;

  const IssueSheetHost({
    required this.subject,
    required this.stopText,
    required this.successAction,
    required this.successText,
    this.request,
    this.beforeAdd,
    this.successLink,
    this.successOffer,
    this.hasOtherChoices = false,
    this.onSucceeded,
    this.onSessionEnded,
    this.routeContext,
  });

  /// A sheet that adds a card on its own (Add data, the scanner over the
  /// lock screen): no request under it, the card as the subject, and
  /// "Done" on "Success" calls [onDone].
  factory IssueSheetHost.standalone(
    BuildContext context, {
    required VoidCallback onDone,
    IssueSuccessLink? Function(List<Credential> cards)? successLink,
    IssueSuccessOffer? Function(List<Credential> cards)? successOffer,
    bool Function(List<Credential> cards)? onSucceeded,
    VoidCallback? onSessionEnded,
    BuildContext Function()? routeContext,
  }) => IssueSheetHost(
    subject: (_) => const IssueSheetSubject.none(),
    stopText: () => context.tr("data.add.stop_text"),
    successText: (cards) => context.tr(
      cards.length > 1
          ? "issuance.success_feedback.added_many"
          : "issuance.success_feedback.added_one",
      {"name": cards.firstOrNull?.name ?? "", "count": "${cards.length}"},
    ),
    successAction: (cards) => SheetAction(
      key: const Key("sheet_done"),
      label: context.tr("ui.done"),
      onTap: onDone,
    ),
    successLink: successLink,
    successOffer: successOffer,
    onSucceeded: onSucceeded,
    onSessionEnded: onSessionEnded,
    routeContext: routeContext,
  );
}

/// The keys of a sheet's flow: where the pictures and headings of its
/// pages are, for the flights between them and the titles in the bar. The
/// sheet's state owns them.
class IssueSheetKeys {
  /// Where step 1's picture is: a card lifted from the share screen lands
  /// there.
  final hero = GlobalKey(debugLabel: "issue_hero");

  /// The issuer's logo on the question page, and on the issuer's page: it
  /// flies between them as the page slides in and out.
  final issuerLogoFrom = GlobalKey(debugLabel: "issuer_logo_from");
  final issuerLogoTo = GlobalKey(debugLabel: "issuer_logo_to");

  /// The issuer's card on the permission: once it has gone up under the
  /// bar, the issuer sticks in a row under the bar.
  final issuerCard = GlobalKey(debugLabel: "issuer_card");

  /// The issuer's logo on the details' issuer card, and on the issuer's page
  /// over the details: their own pair, as the details stay under the
  /// question (which has the other pair).
  final detailsLogoFrom = GlobalKey(debugLabel: "details_issuer_logo_from");
  final detailsLogoTo = GlobalKey(debugLabel: "details_issuer_logo_to");

  final _titles = <String, GlobalKey>{};

  /// The big heading of [page]: the bar's title shows once it has scrolled
  /// under the bar.
  GlobalKey title(String page) =>
      _titles[page] ??= GlobalKey(debugLabel: "issue_title_$page");

  List<Credential>? _addedFor;
  List<GlobalKey> _added = const [];

  /// Where each of the added [cards] is drawn on "Success", to fly from.
  List<GlobalKey> added(List<Credential>? cards) {
    if (cards != null && !identical(cards, _addedFor)) {
      _addedFor = cards;
      _added = [
        for (final (i, _) in cards.indexed)
          GlobalKey(debugLabel: "sheet_added_$i"),
      ];
    }
    return _added;
  }
}

/// Closes a sheet that adds a card ([config]) on the page it is on, from
/// the sheet's own state; what is left running ends once it has gone.
void closeIssueSheet(
  BuildContext context,
  WidgetRef ref,
  IssueFlowConfig config,
) {
  ref.read(issueFlowProvider(config).notifier).startClosing();
  Navigator.of(context).pop();
}

/// Adding a card inside a sheet, in three steps under an
/// [IssueSheetProgress]: 1 its details (as on the add-data page), 2 proving
/// it (Yivi's own e-mail, phone or document steps, or the issuer's website,
/// from which the user comes back to the sheet), and 3 the issuance itself
/// ("Do you want to add this data?", the PIN if irmago asks, then
/// "Success"). Once adding has started, closing the sheet asks first.
///
/// The sheet's own [root] page (under the key [rootKey]) comes first, then
/// the flow's pages ([issueFlowPages]). Opened on one card, the flow's
/// first page takes the root's place. [below]: pages under the root, each
/// with a key of its own (the sheet adding was started from, as "Welk
/// kaartje deel je?"); without a [root] the flow's pages go straight on
/// them.
class IssueSheet extends StatelessWidget {
  final IssueFlowConfig config;
  final IssueSheetHost host;
  final IssueSheetKeys keys;
  final String rootKey;
  final Widget? root;
  final List<Widget> below;

  /// Called on back in the sheet, before it goes back.
  final VoidCallback? onBack;

  /// See [SheetPages.rootShift].
  final double? rootShift;

  const IssueSheet({
    super.key,
    required this.config,
    required this.host,
    required this.keys,
    required this.rootKey,
    required this.root,
    this.below = const [],
    this.onBack,
    this.rootShift,
  });

  @override
  Widget build(BuildContext context) => IssueFlowScope(
    config: config,
    host: host,
    keys: keys,
    builder: (context, flow) => flow._sheet(
      rootKey: rootKey,
      root: root,
      below: below,
      onBack: onBack,
      rootShift: rootShift,
    ),
  );
}

/// Adding a card in a sheet: follows the sheet's [IssueFlowController] and
/// does for it what needs the sheet's context. [builder] puts the flow's
/// pages ([issueFlowPages]) in the sheet; [IssueSheet] for most sheets.
class IssueFlowScope extends ConsumerStatefulWidget {
  final IssueFlowConfig config;
  final IssueSheetHost host;
  final IssueSheetKeys keys;
  final Widget Function(BuildContext context, IssueSheetFlow flow) builder;

  const IssueFlowScope({
    super.key,
    required this.config,
    required this.host,
    required this.keys,
    required this.builder,
  });

  @override
  ConsumerState<IssueFlowScope> createState() => IssueSheetFlow();
}

/// The flow of one sheet as its pages use it: where it is ([now]), and
/// what needs the sheet (the flights of the issuer's logo, asking before
/// adding stops, pages over the sheet, closing it).
class IssueSheetFlow extends ConsumerState<IssueFlowScope>
    implements IssueFlowHost {
  IssueFlowConfig get config => widget.config;
  IssueSheetHost get host => widget.host;
  IssueSheetKeys get keys => widget.keys;

  late final ProviderSubscription<IssueFlowState> _sub;

  /// The sheet's flow.
  late final IssueFlowController controller;

  /// Where the flow is now.
  IssueFlowState get now => _sub.read();

  @override
  void initState() {
    super.initState();
    _sub = ref.listenManual(issueFlowProvider(config), (_, _) {});
    controller = ref.read(issueFlowProvider(config).notifier)..bind(this);
    // On step 2 at once, as if "Add" had been tapped on the details.
    if (config.start case final d? when config.prove) {
      afterFrame(() => add(d));
    }
  }

  @override
  void dispose() {
    controller.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(issueFlowProvider(config));
    return widget.builder(context, this);
  }

  // ---------- what the flow asks of the sheet ----------

  @override
  bool onSucceeded(List<Credential> cards) =>
      mounted && (host.onSucceeded?.call(cards) ?? false);

  @override
  void onSessionEnded() {
    if (mounted) host.onSessionEnded?.call();
  }

  @override
  Future<void> showOverSheet(SessionView view) async {
    if (!mounted) return;
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (context) => switch (view) {
          SessionFailed(:final error, :final state) => SessionErrorScreen(
            // The error as Go sent it (it may have none); else why the
            // state could not be shown.
            error: state?.status == SessionStatus.error ? state!.error : error,
            onTapClose: () => Navigator.of(context).pop(),
            organisation: SupportParty.resolve(state?.requestor, null),
          ),
          _ => TxCodeLockoutScreen(
            onTapClose: () => Navigator.of(context).pop(),
          ),
        },
      ),
    );
  }

  @override
  void handOver(int sessionId) {
    if (!mounted) return;
    (host.routeContext?.call() ?? context).pushSessionScreen(
      SessionRouteParams(
        sessionId: sessionId,
        hasUnderlyingSession: host.request != null,
      ),
    );
  }

  // ---------- the steps ----------

  /// How adding [d] goes: Yivi's own steps or the issuer's website.
  IssuePlan planOf(CredentialDescriptor d) =>
      issuePlanOf(d, embeddedFlowOf(d.credentialId));

  /// How many steps adding [d] takes, for the progress ([IssuePlan.total]);
  /// a document's own count once its flow has started. Only while the
  /// sheet builds.
  int stepsOf(CredentialDescriptor d) => planOf(d).total(
    documentTotal: switch (now.document) {
      final type? => ref.watch(documentFlowProvider(type)).total,
      null => null,
    },
  );

  /// "Add" on the details: Yivi's own e-mail, phone or document steps in the
  /// sheet, or the issuer's website with the sheet waiting for what comes
  /// back. Either way the issuance then shows in the sheet.
  void add(CredentialDescriptor d) {
    host.beforeAdd?.call(d);
    controller.add(d);
  }

  /// "Open website" on the website page: the sheet waits for what comes
  /// back from the issuer.
  Future<void> openWebsite(CredentialDescriptor d) async {
    controller.websiteOpened();
    await ref.read(issuerOpenerProvider)(d);
  }

  /// Back from the website page to the details. Once the website was
  /// opened, adding has started: it asks first, and stopping ends the wait.
  Future<void> leaveWebsite() async {
    if (now.opened) {
      final stop = await confirmStop(closing: false);
      // Stopped, adding has ended and the details show; not asked (nothing
      // was started), only the page goes.
      if (!stop || !mounted || now.stack.lastOrNull is! WebsiteStep) return;
    }
    controller.back();
  }

  /// "Choose something else" on the website step: adding stops (after
  /// asking, once the website was opened) and the sheet's root page shows.
  Future<void> chooseOther() async {
    if (now.opened && !await confirmStop(closing: false)) return;
    if (!mounted) return;
    controller.chooseOther();
  }

  /// Back from the details to the root page, leaving nothing behind. When
  /// the details are the sheet's first page, the sheet closes instead.
  void leave() {
    if (now.direct) {
      // Asked already where it had to be (or nothing was started yet).
      close();
      return;
    }
    controller.leave();
  }

  /// Closes the sheet on the page it is on; what is left running ends once
  /// it has gone.
  void close() {
    controller.startClosing();
    Navigator.of(context).pop();
  }

  /// "Stop adding {name}?" before a started adding is left. When the sheet
  /// is [closing] it stays on its page while it goes, and the adding ends
  /// once it has gone.
  Future<bool> confirmStop({bool closing = true}) async {
    final d = now.adding;
    if (d == null || !now.started) return true;
    final stop =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => YiviDialog(
            cardKey: const Key("sheet_stop_dialog"),
            title: context.tr("share.sheet.stop_title", {
              "name": inSentenceAt(context, d.name),
            }),
            message: host.stopText(),
            actions: [
              PillButton(
                key: const Key("sheet_stop_confirm"),
                label: context.tr("share.sheet.stop_confirm"),
                style: PillStyle.dangerFilled,
                onPressed: () => Navigator.of(dialogContext).pop(true),
              ),
              PillButton(
                key: const Key("sheet_stop_keep"),
                label: context.tr("share.sheet.keep_going"),
                style: PillStyle.text,
                onPressed: () => Navigator.of(dialogContext).pop(false),
              ),
            ],
          ),
        ) ??
        false;
    if (stop && closing) {
      controller.startClosing();
    } else if (stop) {
      controller.stopAdding();
    }
    return stop;
  }

  /// Back in the sheet: one step back, or from the details to the root page
  /// ([IssueFlowController.back]). The issuer's pages take their logo back
  /// with them, an opened website asks first, and the details of a sheet
  /// opened on them close it.
  void back() {
    final s = now;
    switch (s.stack.lastOrNull) {
      // Swiped back, the page is out of the sheet already: no logo flies
      // back from there.
      case DetailsIssuerStep():
        final issuer = s.adding?.issuer;
        if (issuer != null && !_pageOut(keys.detailsLogoTo)) {
          closeDetailsIssuer(issuer);
          return;
        }
      case IssuerStep(technical: false):
        final issuer = s.lastOffer?.offeredCredentials?.firstOrNull?.issuer;
        if (issuer != null && !_pageOut(keys.issuerLogoTo)) {
          closeIssuerPage(issuer);
          return;
        }
      case WebsiteStep(opened: true):
        leaveWebsite();
        return;
      case DetailsStep() when s.direct:
        leave();
        return;
      case _:
    }
    controller.back();
  }

  // ---------- the issuer's pages ----------

  /// The issuer's page slides in over the question; its logo grows from the
  /// question's into its own (360 ms, with the slide).
  void openIssuerPage(TrustedParty issuer) {
    Flight.hide([keys.issuerLogoTo]);
    controller.openIssuer();
    afterFrame(() {
      Flight.show([keys.issuerLogoTo]);
      _flyIssuerLogo(issuer, from: keys.issuerLogoFrom, to: keys.issuerLogoTo);
    });
  }

  /// Back to the question: the logo shrinks back into the question's.
  void closeIssuerPage(TrustedParty issuer) {
    _flyIssuerLogo(issuer, from: keys.issuerLogoTo, to: keys.issuerLogoFrom);
    controller.closeIssuer();
  }

  /// The issuer's page slides in over the details, its logo growing from
  /// the issuer card's.
  void openDetailsIssuer(TrustedParty issuer) {
    Flight.hide([keys.detailsLogoTo]);
    controller.openDetailsIssuer();
    afterFrame(() {
      Flight.show([keys.detailsLogoTo]);
      _flyIssuerLogo(
        issuer,
        from: keys.detailsLogoFrom,
        to: keys.detailsLogoTo,
      );
    });
  }

  /// Back to the details: the logo shrinks back into the issuer card's.
  void closeDetailsIssuer(TrustedParty issuer) {
    _flyIssuerLogo(issuer, from: keys.detailsLogoTo, to: keys.detailsLogoFrom);
    controller.closeDetailsIssuer();
  }

  /// The issuer's page with the logo at [logoKey] is out of the sheet, to
  /// its right (swiped back).
  bool _pageOut(GlobalKey logoKey) {
    final logo = logoKey.currentContext?.findRenderObject();
    final sheet = context.findRenderObject();
    if (logo is! RenderBox || sheet is! RenderBox) return true;
    if (!logo.hasSize || !sheet.hasSize) return true;
    final right = sheet.localToGlobal(Offset(sheet.size.width, 0)).dx;
    return logo.localToGlobal(Offset.zero).dx >= right - 1;
  }

  void _flyIssuerLogo(
    TrustedParty issuer, {
    required GlobalKey from,
    required GlobalKey to,
  }) {
    final style = RequestorTrustStyle.of(context, issuer);
    Flight.start(
      context,
      from: from,
      to: Flight.boxOf(to),
      keys: const [FlightKey(0, FlightKey.start), FlightKey(1, FlightKey.end)],
      duration: SheetPages.slideDuration,
      curve: YiviMotion.ease,
      hide: [from, to],
      copy: (context, frame) => RequestorLogo(
        requestor: issuer,
        style: style,
        size: frame.size.width,
      ),
    );
  }

  // ---------- the sheet ----------

  /// The pages while the sheet closes: it keeps those it had until it has
  /// gone, instead of going back to an earlier one on the way out.
  List<Widget>? _shownPages;

  Widget _sheet({
    required String rootKey,
    required Widget? root,
    required List<Widget> below,
    required VoidCallback? onBack,
    required double? rootShift,
  }) {
    // Popped, however (its close button, a drag, a tap outside, Done): the
    // sheet keeps its pages while it goes.
    final route = ModalRoute.of(context);
    if (route != null && !route.isActive && !controller.closing) {
      controller.startClosing();
    }
    final closing = controller.closing;
    final s = now;
    // The island over the sheet: why the card is added, during a request.
    // Not over the sheet's root page or once the card is in.
    final request = host.request;
    final island =
        s.island &&
        request != null &&
        s.adding != null &&
        s.added == null &&
        !closing;
    return SheetConfirmDismiss(
      ask: s.started,
      confirm: confirmStop,
      // On a phone held upright the close button stays at the top right on
      // every page of adding. Sideways the way on is in the bar, in the
      // close button's place, with the progress after "For …".
      child: SheetKeepsClose(
        child: Builder(
          builder: (_) => IssueIslandScope(
            open: controller.openIsland,
            isOpen: island,
            child: Stack(
              // The pages get the sheet's own constraints: a short page
              // still makes a low sheet.
              fit: StackFit.passthrough,
              children: [
                SheetPages(
                  onBack: () {
                    onBack?.call();
                    back();
                  },
                  rootShift: rootShift,
                  pages: closing && _shownPages != null
                      ? _shownPages!
                      : _shownPages = [
                          ...below,
                          if (root != null && (!s.direct || s.adding == null))
                            KeyedSubtree(key: ValueKey(rootKey), child: root),
                          ...issueFlowPages(this),
                        ],
                ),
                if (island)
                  Positioned.fill(
                    child: IssueIsland(
                      requestor: request.requestor,
                      signing: request.type == SessionType.signature,
                      onClose: controller.closeIsland,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
