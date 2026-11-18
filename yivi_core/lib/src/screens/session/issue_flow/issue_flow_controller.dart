import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:vcmrtd/vcmrtd.dart" show DocumentType;

import "../../../data/irma_repository.dart";
import "../../../models/credential.dart";
import "../../../models/credential_store.dart";
import "../../../models/session_state.dart";
import "../../../providers/contact_issuance_provider.dart";
import "../../../providers/irma_repository_provider.dart";
import "../../../providers/nested_issuance_host_provider.dart";
import "../../../providers/session_flow_provider.dart";
import "../../embedded_issuance_flows/documents/document_flow.dart";
import "../models/session_view.dart";

/// A page of adding a card in a sheet, bottom first. The sheet's own root
/// page is under them all and is not a step.
sealed class IssueStep {
  const IssueStep();
}

/// Step 1: what the card [d] is, as on the add-data page.
final class DetailsStep extends IssueStep {
  final CredentialDescriptor d;
  const DetailsStep(this.d);
}

/// The issuer's page over the details, from the ⓘ on its issuer card.
final class DetailsIssuerStep extends IssueStep {
  const DetailsIssuerStep();
}

/// Step 2 for a card from a website: where adding goes, and the way there.
/// [opened]: the website was opened, and the sheet waits for what comes
/// back.
final class WebsiteStep extends IssueStep {
  final bool opened;
  const WebsiteStep({this.opened = false});
}

/// Step 2: Yivi's own e-mail or phone step ([flow]).
final class ContactStep extends IssueStep {
  final ContactFlow flow;
  const ContactStep(this.flow);
}

/// Step 2: the document screens for [type].
final class DocumentStepPage extends IssueStep {
  final DocumentType type;
  const DocumentStepPage(this.type);
}

/// Step 3: the issuance [sessionId] that came back from the issuer (the
/// offer, or OpenID4VCI's own steps before it).
final class IssueSessionStep extends IssueStep {
  final int sessionId;
  const IssueSessionStep(this.sessionId);
}

/// The issuer's details over the offer, from its trust label; [technical]:
/// their technical details, over those.
final class IssuerStep extends IssueStep {
  final bool technical;
  const IssuerStep({this.technical = false});
}

/// The PIN for issuance [sessionId], while irmago asks for it. Once shown
/// it stays under "Success", so "Success" comes in over it.
final class PinStep extends IssueStep {
  final int sessionId;
  const PinStep(this.sessionId);
}

/// "Success": the [cards] of the finished issuance, kept (the session state
/// moves on once a request picks them up).
final class SuccessStep extends IssueStep {
  final List<Credential> cards;
  const SuccessStep(this.cards);
}

/// Where adding a card in a sheet is: its pages ([stack]) and what the
/// pages do not say.
@immutable
final class IssueFlowState {
  /// The pages after the sheet's root page, bottom first; empty: the root
  /// page.
  final List<IssueStep> stack;

  /// The sheet opened straight on the card being added: its details are the
  /// sheet's first page, with nothing to go back to.
  final bool direct;

  /// The sheet takes the next session that starts, without a type picked
  /// first ([IssueFlowController.takeSession]).
  final bool standalone;

  /// The island over the sheet: why the card is added, during a request.
  final bool island;

  /// "Add" was tapped on the offer: a second tap does nothing, and the offer
  /// stays as it was until "Success" or the PIN.
  final bool granted;

  /// The last offer of the issuance, for the offer page while "Success"
  /// covers it, after "Add", and for the issuer's pages.
  final SessionState? lastOffer;

  /// OpenID4VCI sessions whose login page in the browser was opened.
  final Set<int> authOpened;

  const IssueFlowState({
    this.stack = const [],
    this.direct = false,
    this.standalone = false,
    this.island = false,
    this.granted = false,
    this.lastOffer,
    this.authOpened = const {},
  });

  T? _last<T extends IssueStep>() => stack.whereType<T>().lastOrNull;

  /// The type being added; null on the root page, and for a session taken
  /// without a type picked first.
  CredentialDescriptor? get adding => switch (stack.firstOrNull) {
    DetailsStep(:final d) => d,
    _ => null,
  };

  /// The issuance in the sheet.
  int? get sessionId => _last<IssueSessionStep>()?.sessionId;

  /// The cards of the finished issuance, on "Success".
  List<Credential>? get added => _last<SuccessStep>()?.cards;

  bool get detailsIssuer => stack.any((s) => s is DetailsIssuerStep);

  bool get website => stack.any((s) => s is WebsiteStep);

  /// The issuer's website was opened.
  bool get opened => _last<WebsiteStep>()?.opened ?? false;

  ContactFlow? get contact => _last<ContactStep>()?.flow;

  DocumentType? get document => _last<DocumentStepPage>()?.type;

  /// The issuer's pages over the offer: 1 their details, 2 also the
  /// technical details.
  int get issuerDepth => stack.whereType<IssuerStep>().length;

  /// irmago asks for the PIN now.
  bool get pin => stack.lastOrNull is PinStep;

  /// The PIN page is shown: asked for now, or kept under "Success".
  bool get pinShown => stack.any((s) => s is PinStep);

  /// An issuance is in the sheet: started, or finished on "Success".
  bool get hasSession => sessionId != null || added != null;

  /// Adding has started: closing asks first. Not on the details, where
  /// nothing has happened yet, and not once the card is in.
  bool get started =>
      adding != null &&
      added == null &&
      stack.any(
        (s) =>
            s is WebsiteStep ||
            s is ContactStep ||
            s is DocumentStepPage ||
            s is IssueSessionStep ||
            s is PinStep,
      );

  IssueFlowState copyWith({
    List<IssueStep>? stack,
    bool? direct,
    bool? standalone,
    bool? island,
    bool? granted,
    SessionState? Function()? lastOffer,
    Set<int>? authOpened,
  }) => IssueFlowState(
    stack: stack ?? this.stack,
    direct: direct ?? this.direct,
    standalone: standalone ?? this.standalone,
    island: island ?? this.island,
    granted: granted ?? this.granted,
    lastOffer: lastOffer == null ? this.lastOffer : lastOffer(),
    authOpened: authOpened ?? this.authOpened,
  );
}

/// What a sheet that adds a card does for its flow and needs its
/// `BuildContext` for.
abstract interface class IssueFlowHost {
  /// The issuance in the sheet succeeded. True: the host took over, and
  /// "Success" is not shown.
  bool onSucceeded(List<Credential> cards);

  /// A session taken without a type picked first ended without being
  /// added: declined, dismissed, handed over, or an error was closed.
  void onSessionEnded();

  /// Shows [view] (an error, or the transaction-code lockout) over the
  /// sheet; completes once it is closed.
  Future<void> showOverSheet(SessionView view);

  /// Session [sessionId] is not an issuance the sheet can show (a pairing
  /// code, a request): it gets the session screen.
  void handOver(int sessionId);
}

/// What differs per sheet. Compared by identity: the sheet's state creates
/// it once, so each sheet has its own controller.
final class IssueFlowConfig {
  /// The request a card is added for; null: Add data, the lock scanner.
  final int? requestId;

  /// The e-mail step links the address to the keyshare server.
  final bool linking;

  /// The sheet opens straight on this type's details.
  final CredentialDescriptor? start;

  /// The sheet opens on step 2 for [start] at once, as if "Add" had been
  /// tapped on its details.
  final bool prove;

  IssueFlowConfig({
    this.requestId,
    this.linking = false,
    this.start,
    this.prove = false,
  });
}

/// The flow of adding a card in one sheet.
final issueFlowProvider = NotifierProvider.autoDispose
    .family<IssueFlowController, IssueFlowState, IssueFlowConfig>(
      IssueFlowController.new,
    );

/// Adding a card inside a sheet: its details, proving it (Yivi's own
/// steps, or the issuer's website), and the issuance that comes back
/// ([attach]). Follows that issuance's [sessionFlowProvider] and ends what
/// was left running when the sheet is gone.
class IssueFlowController extends Notifier<IssueFlowState>
    implements NestedIssuanceHost {
  IssueFlowController(this.config);

  final IssueFlowConfig config;

  late NestedIssuanceHostNotifier _hosts;

  // The repository only once something needed it, kept for the end (where
  // ref can't be used). Not read when nothing was started: a sheet that
  // only showed its root page never touches it.
  IrmaRepository? _repoRead;
  IrmaRepository get _repo {
    final read = _repoRead;
    if (read != null) return read;
    final repo = ref.read(irmaRepositoryProvider);
    _repoRead = repo;
    return repo;
  }

  ProviderSubscription<SessionView>? _session;
  int? _sessionFor;

  /// A page is shown over the sheet for the issuance (an error).
  bool _overSheet = false;

  /// The sheet is closing ([startClosing]).
  bool _closing = false;

  /// The sheet has gone ([detach]); the provider follows a frame later.
  bool _detached = false;

  IssueFlowHost? _host;

  /// The sheet, while it is there ([bind] until [detach]).
  IssueFlowHost? get _sheet => _detached ? null : _host;

  /// Whether the sheet is closing ([startClosing]).
  bool get closing => _closing;

  /// The sheet that shows this flow: it is told what the flow needs of it.
  void bind(IssueFlowHost host) => _host = host;

  @override
  int? get underlyingSessionId => config.requestId;

  @override
  IssueFlowState build() {
    _hosts = ref.read(nestedIssuanceHostProvider.notifier);
    final container = ref.container;
    ref.onDispose(() => _end(container));
    final start = config.start;
    return _now = IssueFlowState(
      stack: [if (start != null) DetailsStep(start)],
      direct: start != null,
    );
  }

  /// The state as last set: [state] can't be read once the provider is
  /// being disposed.
  late IssueFlowState _now;

  /// The sheet has gone: ends what adding left running. Closed while
  /// adding, also the launch record and the e-mail or phone step. Right
  /// after the provider is disposed: no other provider may change while it
  /// is.
  void _end(ProviderContainer container) {
    final s = _now;
    final repo = _repoRead;
    final closing = _closing;
    final hosts = _hosts;
    Future.microtask(() {
      hosts.unregister(this);
      if (s.added != null) return;
      if (s.sessionId case final id?) repo?.sessions.dismissSession(id);
      if (!closing) return;
      if (s.opened) repo?.clearInAppLaunches();
      if (s.contact != null) {
        container
          ..invalidate(contactIssuanceProvider(ContactFlow.email))
          ..invalidate(contactIssuanceProvider(ContactFlow.phone))
          ..invalidate(contactIssuanceProvider(ContactFlow.linkEmail));
      }
    });
  }

  /// Sets [next] and follows its issuance, if it has another one.
  void _set(IssueFlowState next) {
    state = _now = next;
    final id = next.sessionId;
    if (id == _sessionFor) return;
    _session?.close();
    _session = null;
    _sessionFor = id;
    if (id == null) return;
    final sub = ref.listen(sessionFlowProvider(id), _onSession);
    _session = sub;
    if (sub.read() case SessionOffer(:final state)) {
      this.state = _now = _now.copyWith(lastOffer: () => state);
    }
  }

  /// [stack] without the topmost [T] and what is over it.
  static List<IssueStep> _below<T extends IssueStep>(List<IssueStep> stack) {
    final i = stack.lastIndexWhere((s) => s is T);
    return i < 0 ? stack : stack.sublist(0, i);
  }

  /// The issuance is gone: no session, its pages, the PIN, "Success" and
  /// the offer kept.
  IssueFlowState _forget(IssueFlowState s) => s.copyWith(
    stack: _below<IssueSessionStep>(s.stack),
    granted: false,
    lastOffer: () => null,
  );

  /// Only the details are left of the steps: none of the steps that prove
  /// the card is under way.
  IssueFlowState _clearSteps(IssueFlowState s) =>
      s.copyWith(stack: [?s.stack.whereType<DetailsStep>().firstOrNull]);

  // ---------- the steps ----------

  /// Opens the details of [d] (step 1).
  void open(CredentialDescriptor d) =>
      _set(state.copyWith(stack: [DetailsStep(d)], direct: false));

  /// "Add" on the details of [d]: Yivi's own e-mail, phone or document
  /// steps, or the page that sends the user to the issuer's website.
  void add(CredentialDescriptor d) {
    final flow = _repo.embeddedFlowOf(d.credentialId);
    final contact = switch (flow) {
      EmbeddedFlow.phone => ContactFlow.phone,
      EmbeddedFlow.email when config.linking => ContactFlow.linkEmail,
      EmbeddedFlow.email => ContactFlow.email,
      _ => null,
    };
    final document = flow == EmbeddedFlow.document
        ? documentTypeOf(d.credentialId)
        : null;
    final IssueStep step;
    if (contact != null || document != null) {
      if (!_repo.prepareEmbeddedFlow(d.credentialId, d.issueURL, ref.read)) {
        return;
      }
      _hosts.register(this);
      step = contact != null
          ? ContactStep(contact)
          : DocumentStepPage(document!);
    } else {
      // The issuer's website (every document Yivi issues itself has a
      // DocumentType): first the page that says so.
      step = const WebsiteStep();
    }
    _set(state.copyWith(stack: [...state.stack, step]));
  }

  /// "Open website" on the website page: the sheet waits for what comes
  /// back from the issuer.
  void websiteOpened() {
    _hosts.register(this);
    final stack = state.stack;
    final i = stack.lastIndexWhere((s) => s is WebsiteStep);
    if (i < 0) return;
    _set(
      state.copyWith(stack: [...stack]..[i] = const WebsiteStep(opened: true)),
    );
  }

  /// The issuer's page over the details.
  void openDetailsIssuer() =>
      _set(state.copyWith(stack: [...state.stack, const DetailsIssuerStep()]));

  void closeDetailsIssuer() =>
      _set(state.copyWith(stack: _below<DetailsIssuerStep>(state.stack)));

  /// The issuer's details over the offer ([technical]: their technical
  /// details over those).
  void openIssuer({bool technical = false}) => _set(
    state.copyWith(
      stack: [
        ...state.stack,
        IssuerStep(technical: technical),
      ],
    ),
  );

  /// Back to the offer from the issuer's pages; [technical]: only from the
  /// technical details, to the issuer's.
  void closeIssuer({bool technical = false}) {
    final stack = state.stack;
    final i = stack.indexWhere(
      (s) => s is IssuerStep && (!technical || s.technical),
    );
    if (i >= 0) _set(state.copyWith(stack: stack.sublist(0, i)));
  }

  /// Back from the e-mail or phone step to the details.
  void leaveContact() =>
      _set(state.copyWith(stack: _below<ContactStep>(state.stack)));

  /// Back from the document screens to the details.
  void leaveDocument() =>
      _set(state.copyWith(stack: _below<DocumentStepPage>(state.stack)));

  void openIsland() => _set(state.copyWith(island: true));

  void closeIsland() {
    if (state.island) _set(state.copyWith(island: false));
  }

  /// Back in the sheet: the page on top goes, and what it started ends.
  ///
  /// - The issuer's pages: back to what is under them.
  /// - The PIN: declines the issuance, which ends it (see [attach]).
  /// - The issuance: declines it; a session taken without a type picked
  ///   first only that (it ends once irmago says it is dismissed),
  ///   otherwise a step back at once: a document's chip screen, to read it
  ///   again; the website or the address page, as they were.
  /// - The document screens: the details.
  /// - The website: the details; once it was opened, no longer waits.
  /// - The e-mail or phone step: from the code to the address, from the
  ///   address to the details.
  /// - The details: the root page, ending what adding left running. Not
  ///   when the sheet opened on them ([IssueFlowState.direct]): the sheet
  ///   closes then, which is the host's.
  /// - "Success": nothing; its way on is the way out.
  void back() {
    final s = state;
    switch (s.stack.lastOrNull) {
      case null || SuccessStep():
        return;
      case DetailsIssuerStep():
        closeDetailsIssuer();
      case IssuerStep(:final technical):
        closeIssuer(technical: technical);
      case PinStep(:final sessionId):
        _repo.sessions.dismissSession(sessionId);
      case IssueSessionStep(:final sessionId):
        _repo.sessions.dismissSession(sessionId);
        if (s.standalone && s.adding == null) return;
        _set(_forget(s));
        _backToChip();
      case DocumentStepPage():
        leaveDocument();
      case WebsiteStep(:final opened):
        if (opened) {
          _repo.clearInAppLaunches();
          _hosts.unregister(this);
        }
        _set(s.copyWith(stack: _below<WebsiteStep>(s.stack)));
      case ContactStep(:final flow):
        final notifier = ref.read(contactIssuanceProvider(flow).notifier);
        if (ref.read(contactIssuanceProvider(flow)).stage ==
            ContactStage.code) {
          notifier.backToAddress();
        } else {
          leaveContact();
        }
      case DetailsStep():
        if (!s.direct) leave();
    }
  }

  /// From the details to the root page, ending what adding left running.
  void leave() {
    stopAdding();
    _set(state.copyWith(stack: const []));
  }

  /// Ends what adding left running (the issuance, the wait for it, the
  /// launch record, the e-mail or phone step): only the details are left.
  void stopAdding() {
    final s = state;
    final id = s.sessionId;
    if (id != null && s.added == null) _repo.sessions.dismissSession(id);
    _hosts.unregister(this);
    if (s.opened) _repo.clearInAppLaunches();
    if (s.contact != null) {
      ref
        ..invalidate(contactIssuanceProvider(ContactFlow.email))
        ..invalidate(contactIssuanceProvider(ContactFlow.phone))
        ..invalidate(contactIssuanceProvider(ContactFlow.linkEmail));
    }
    _set(_clearSteps(_forget(s)));
  }

  /// "Choose something else" on the website step: adding stops and the
  /// sheet's root page shows.
  void chooseOther() {
    stopAdding();
    _set(state.copyWith(stack: const [], direct: false));
  }

  /// Back to the step before the issuance (the website, the code), to try
  /// again after a card that does not count came back.
  void retry() {
    back();
    final stack = state.stack;
    if (stack.lastOrNull is WebsiteStep) {
      _set(state.copyWith(stack: [...stack]..last = const WebsiteStep()));
    }
  }

  /// Done with a finished issuance: the flow starts over on the root page.
  /// A sheet that opened straight on the card keeps that while it closes.
  void reset() => _set(_forget(state).copyWith(stack: const []));

  /// After a finished issuance, on to the sheet's root page (Add more),
  /// also when the sheet opened straight on the card.
  void showRoot() {
    reset();
    _set(state.copyWith(direct: false));
  }

  /// The sheet is closing: it stays on its page while it goes, and what was
  /// left running ends once it has gone. Changes nothing the sheet shows,
  /// so it may be called while the sheet builds.
  void startClosing() {
    _closing = true;
    if (state.sessionId != null || state.opened) _repo;
  }

  // ---------- the issuance ----------

  /// Takes the next session that starts into this sheet (an issuance
  /// scanned on the lock screen), without a type picked first.
  void takeSession() {
    _set(state.copyWith(standalone: true));
    _hosts.register(this);
  }

  /// No longer takes the next session ([takeSession]).
  void releaseSession() {
    _hosts.unregister(this);
    if (state.sessionId == null && state.standalone) {
      _set(state.copyWith(standalone: false));
    }
  }

  /// The sheet's state is disposed: it no longer takes a session, and is
  /// no longer called. Ending what was left running follows once the
  /// provider is disposed. Changes no provider now (the tree is being torn
  /// down): the wait for a session ends right after.
  void detach() {
    _detached = true;
    Future.microtask(() {
      if (ref.mounted) _hosts.unregister(this);
    });
  }

  @override
  void attach(int sessionId) {
    if (!ref.mounted || _detached) return;
    final s = state;
    final previous = s.sessionId;
    if (previous != null && previous != sessionId) {
      _repo.sessions.dismissSession(previous);
    }
    _set(
      s.copyWith(
        stack: [
          ..._below<IssueSessionStep>(s.stack),
          IssueSessionStep(sessionId),
        ],
        granted: false,
        lastOffer: () => null,
      ),
    );
  }

  /// "Add" on the offer, once.
  void grant() {
    final id = state.sessionId;
    if (state.granted || id == null) return;
    _set(state.copyWith(granted: true));
    _repo.sessions.grantSession(id);
  }

  /// Declines the issuance in the sheet; what follows comes from irmago.
  void dismissSession() {
    if (state.sessionId case final id?) _repo.sessions.dismissSession(id);
  }

  /// Opens the issuer's login for OpenID4VCI's authorization code at [url].
  Future<void> openAuthorization(int sessionId, String url) async {
    _set(state.copyWith(authOpened: {...state.authOpened, sessionId}));
    await _repo.authenticateOpenID4VCI(url);
  }

  /// Adding a document goes back to its chip screen, which starts over: the
  /// issuer asks for a face check again if it wants one.
  void _backToChip() {
    if (state.document case final type?) {
      ref.read(documentFlowProvider(type).notifier).readAgain();
    }
  }

  void _onSession(SessionView? previous, SessionView next) {
    if (next is SessionOffer) {
      _set(state.copyWith(lastOffer: () => next.state));
    }
    // Only what a state of the session says: not before the first one, and
    // not while a tap waits for Go's answer (the page stays as it was).
    if (next.state == null || next is SessionWaiting) return;
    final s = state;
    final id = s.sessionId;
    if (id == null) return;
    if (next is SessionSucceeded) {
      if (previous is SessionSucceeded) return;
      final cards = next.state.offeredCredentials ?? const <Credential>[];
      _repo.clearInAppLaunches();
      _hosts.unregister(this);
      _set(s.copyWith(stack: [...s.stack, SuccessStep(cards)]));
      _sheet?.onSucceeded(cards);
      return;
    }
    if (next is SessionDismissed) {
      if (previous is SessionDismissed) return;
      _set(_forget(s));
      if (s.standalone && s.adding == null) {
        _sheet?.onSessionEnded();
        return;
      }
      // Cancelled on the permission or the PIN: a step back, to try again.
      _backToChip();
      return;
    }
    // The PIN is a page in the sheet, on top of the issuance, while irmago
    // asks for it.
    final pin = next is SessionPin;
    if (pin && !s.pin) {
      _set(s.copyWith(stack: [...s.stack, PinStep(id)]));
    } else if (!pin && s.pin) {
      _set(s.copyWith(stack: _below<PinStep>(s.stack)));
    }
    if (pin || _overSheet || previous.runtimeType == next.runtimeType) return;
    switch (next) {
      // Over the sheet, then back to it without the session.
      case SessionFailed() || SessionTxLockout():
        final sheet = _sheet;
        if (sheet == null) return;
        _overSheet = true;
        sheet.showOverSheet(next).whenComplete(() {
          _overSheet = false;
          if (!ref.mounted) return;
          _set(_forget(state));
          if (state.standalone && state.adding == null) {
            _sheet?.onSessionEnded();
          }
        });
      // A pairing code, or a request instead of an issuance, takes the
      // session screen, as without the sheet.
      case SessionPairing() || SessionShare():
        _set(_forget(state));
        _sheet?.handOver(next.state!.id);
        if (s.standalone && s.adding == null) _sheet?.onSessionEnded();
      // The offer and OpenID4VCI's own steps are pages of the sheet.
      case _:
    }
  }
}
