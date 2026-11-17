import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:vcmrtd/vcmrtd.dart";

import "../../../providers/ocr_processor_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/i18n.dart";
import "../../../widgets/glass/glass_sheet.dart";
import "../../../widgets/glass/sheet_actions.dart";
import "../../session/widgets/issue_sheet_progress.dart";
import "document_flow.dart";
import "document_flow_steps.dart";
import "document_step_in_sheet.dart";
import "face_verification_intro_screen.dart";

/// Adding a document in a sheet, as one page of it: the sheet's own bar
/// (the title of the screen on top, back, close) and the progress stay put,
/// and the document's screens ([DocumentFlowSteps]: how to hold it, the
/// camera or typing it in, the chip, the face check) change below them, in a
/// navigator of their own built from the [DocumentFlow]. They show without
/// their own bar or Cancel ([DocumentStepInSheet]). Back from the
/// instruction is [onBack]; closing is the sheet's.
///
/// The chip read starts the issuance through `handlePointer`, which hands it
/// to the sheet waiting for it. When the issuer asks for a face check, its
/// intro is the next screen here; only Regula's own liveness screen opens
/// full-screen above the sheet.
class DocumentSheetStep extends ConsumerStatefulWidget {
  final DocumentType type;

  /// What the progress tag names: the request, or the card being added.
  final IssueSheetSubject subject;

  /// Back from the instruction, to the details.
  final VoidCallback onBack;

  const DocumentSheetStep({
    super.key,
    required this.type,
    required this.subject,
    required this.onBack,
  });

  @override
  ConsumerState<DocumentSheetStep> createState() => _DocumentSheetStepState();
}

class _DocumentSheetStepState extends ConsumerState<DocumentSheetStep>
    implements GlassSheetInnerSwipe {
  final _navigator = GlobalKey<NavigatorState>();

  /// The route of each page, for the swipe.
  final _routes = <LocalKey, _SheetScreenRoute<void>>{};

  /// The screen a back swipe is taking away.
  _SheetScreenRoute<void>? _swiping;

  /// The page of the sheet this step is on, to hand back its swipe.
  SheetPageInfo? _page;

  /// A new screen starts with an empty slot in the bar: it puts its own
  /// way on there, or has none.
  late final _observer = _PushObserver(() {
    final context = _navigator.currentContext;
    if (context != null) SheetActionSlot.maybeOf(context)?.set(null);
  });

  DocumentFlow get _flow =>
      ref.read(documentFlowProvider(widget.type).notifier);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A swipe back goes back a screen here, not to the details.
    _page = GlassSheetPages.maybeOf(context)?..setInnerSwipe(this);
  }

  @override
  void dispose() {
    _page?.setInnerSwipe(null);
    super.dispose();
  }

  _SheetScreenRoute<void>? get _topRoute =>
      _routes[ref.read(documentFlowProvider(widget.type)).top.pageKey];

  // Past the instruction a swipe takes the screen on top away, as back
  // does; the instruction itself goes back to the details (the sheet's).
  @override
  bool get enabled {
    final flow = ref.read(documentFlowProvider(widget.type));
    final top = _topRoute;
    return top != null && flow.top is! InstructionStep && top.popGestureEnabled;
  }

  @override
  void start() => (_swiping = _topRoute)?.dragStart();

  @override
  void update(double delta) => _swiping?.dragUpdate(delta);

  @override
  void end(double velocity) {
    _swiping?.dragEnd(velocity);
    _swiping = null;
  }

  /// Back in the bar: a screen back, or from the instruction to the details.
  void _back() {
    if (!_flow.back()) widget.onBack();
  }

  /// Start on the instruction: the camera, or typing it in on a device
  /// without one.
  void _capture() =>
      _flow.capture(hasCamera: ref.read(ocrProcessorProvider) != null);

  Widget _screen(DocumentStep step) => switch (step) {
    InstructionStep() => DocumentFlowSteps.instruction(
      widget.type,
      onStart: _capture,
      onCancel: _back,
    ),
    CaptureStep(manual: false) => DocumentFlowSteps.reader(
      widget.type,
      onRead: _flow.read,
      onManual: _flow.typeIn,
      onCancel: _back,
    ),
    CaptureStep(manual: true) => DocumentFlowSteps.manualEntry(
      widget.type,
      onRead: _flow.read,
      onCancel: _back,
    ),
    ChipStep(:final read) || PreparingStep(:final read) =>
      DocumentFlowSteps.nfc(read.mrz, onCancel: () {}),
    FaceIntroStep() => FaceVerificationIntroScreen(
      onStart: () => _flow.answerFace(true),
      onCancel: () => _flow.answerFace(false),
    ),
  };

  /// One page per screen, bottom first: the chip and the loader after the
  /// face check share one.
  List<Page<void>> _pages(DocumentFlowState flow) {
    final pages = <LocalKey, _ScreenPage>{};
    for (final step in flow.stack) {
      pages[step.pageKey] = _ScreenPage(
        key: step.pageKey,
        builder: (_) => _screen(step),
        animate: !(step is ChipStep && step.instant),
        routes: _routes,
      );
    }
    return pages.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(documentFlowProvider(widget.type));
    // The screens fill the page; upright their buttons are in the page's
    // bottom bar, which stays put while they change.
    return GlassSheetPage.fill(
      // Each screen has its heading in the page; the bar names it once
      // that has scrolled away.
      title: SheetTitle(
        context.tr(flow.titleKey),
        widget: IssueRequestorPill.maybe(widget.subject),
        centred: true,
        reveal: SheetTitleReveal.afterScroll(60),
      ),
      // Left by dragging its header down: no close button.
      exits: SheetExits(onBack: _back, close: SheetClose.none),
      // Above the screens' buttons, staying put while they change (also on
      // a screen without buttons, which keeps their room).
      bottomInBar: true,
      bottom: IssueSheetProgress(step: flow.step, total: flow.total),
      slotBottom: true,
      // System back steps back in the flow first; closing the sheet
      // leaves the screens as they are while it goes.
      // A container of its own: its routes block the semantics of
      // what was painted before them, which would otherwise include the
      // sheet's bar (title, back, close) for screen readers.
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: DocumentStepInSheet(
          flow: _flow,
          child: NavigatorPopHandler(
            onPopWithResult: (_) {
              if (!GlassSheet.of(context).closing) _back();
            },
            child: Semantics(
              container: true,
              explicitChildNodes: true,
              child: Navigator(
                key: _navigator,
                observers: [_observer],
                pages: _pages(flow),
                // A finished swipe took the screen away.
                onDidRemovePage: (page) {
                  _routes.remove(page.key);
                  if (page.key case final key?) _flow.removePage(key);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A screen of the step: [builder] on a [_SheetScreenRoute].
class _ScreenPage extends Page<void> {
  const _ScreenPage({
    required LocalKey super.key,
    required this.builder,
    required this.animate,
    required this.routes,
  });

  final WidgetBuilder builder;

  /// False: in place at once (the chip screen started over).
  final bool animate;
  final Map<LocalKey, _SheetScreenRoute<void>> routes;

  @override
  Route<void> createRoute(BuildContext context) =>
      routes[key!] = _SheetScreenRoute<void>(this);
}

/// A document screen in the sheet: it slides in from the right over the
/// one before, which moves a third of the way left, as the sheet's own pages
/// do. While it moves it has the sheet's colour behind it; once in, the
/// sheet's glass shows through.
class _SheetScreenRoute<T> extends PageRoute<T> {
  _SheetScreenRoute(_ScreenPage page) : super(settings: page);

  _ScreenPage get _page => settings as _ScreenPage;

  /// A back swipe takes this screen away, following the finger
  /// ([GlassSheetInnerSwipe]).
  void dragStart() => navigator?.didStartUserGesture();

  void dragUpdate(double delta) =>
      controller?.value = (controller!.value - delta).clamp(0, 1);

  /// As the sheet's own pages: back when flung right, or let go past half.
  void dragEnd(double velocity) {
    final controller = this.controller!;
    final back = velocity > 500 || (velocity >= -100 && controller.value < 0.5);
    if (back) {
      navigator?.pop();
    } else {
      controller.forward();
    }
    if (!controller.isAnimating) {
      navigator?.didStopUserGesture();
      return;
    }
    late final AnimationStatusListener done;
    done = (_) {
      if (controller.isAnimating) return;
      navigator?.didStopUserGesture();
      controller.removeStatusListener(done);
    };
    controller.addStatusListener(done);
  }

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration =>
      _page.animate ? const Duration(milliseconds: 340) : Duration.zero;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => _page.builder(context);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Under a finger the screens follow it, without a curve.
    final swiped = navigator?.userGestureInProgress ?? false;
    final Animation<double> curve = swiped
        ? animation
        : CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInOutCubic,
          );
    if (MediaQuery.disableAnimationsOf(context)) {
      return FadeTransition(opacity: curve, child: child);
    }
    final Animation<double> behind = swiped
        ? secondaryAnimation
        : CurvedAnimation(
            parent: secondaryAnimation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInOutCubic,
          );
    return SlideTransition(
      position: Tween(
        begin: Offset.zero,
        end: const Offset(-0.3, 0),
      ).animate(behind),
      child: SlideTransition(
        position: Tween(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(curve),
        child: AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, child) {
            final moving = animation.value < 1;
            return DecoratedBox(
              decoration: BoxDecoration(
                color: moving
                    ? YiviPalette.of(context).sheet
                    : const Color(0x00000000),
                boxShadow: moving
                    ? const [
                        BoxShadow(color: Color(0x1F000000), blurRadius: 16),
                      ]
                    : null,
              ),
              child: child,
            );
          },
        ),
      ),
    );
  }
}

/// Calls [onPush] when a screen comes over another one (not the first,
/// as the navigator starts).
class _PushObserver extends NavigatorObserver {
  _PushObserver(this.onPush);

  final VoidCallback onPush;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) onPush();
  }
}
