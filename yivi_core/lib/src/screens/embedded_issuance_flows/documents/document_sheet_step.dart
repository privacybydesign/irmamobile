import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:vcmrtd/vcmrtd.dart";

import "../../../models/mrz.dart";
import "../../../providers/ocr_processor_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../widgets/glass/glass_sheet.dart";
import "../../../widgets/glass/sheet_action_row.dart";
import "../../session/widgets/issue_sheet_progress.dart";
import "document_flow_steps.dart";
import "document_step_in_sheet.dart";
import "document_translation_keys.dart";
import "face_verification_intro_screen.dart";

/// The screens of adding a document, and the step of the sheet's progress
/// each one is. The face check, when the issuer asks for one, is a step of
/// its own after the chip.
enum _Screen {
  instruction(2),
  reader(3),
  manual(3),
  chip(4),
  face(5);

  const _Screen(this.step);
  final int step;
}

/// Adding a document in a sheet, as one page of it: the sheet's own bar
/// (the title of the screen on top, back, close) and the progress stay put,
/// and the document's screens ([DocumentFlowSteps]: how to hold it, the
/// camera or typing it in, the chip, the face check) change below them, in a
/// navigator of their own. They show without their own bar or Cancel
/// ([DocumentStepInSheet]). Back from the instruction is [onBack]; closing
/// is the sheet's.
///
/// The chip read starts the issuance through `handlePointer`, which hands it
/// to the sheet waiting for it. When the issuer asks for a face check, its
/// intro is the next screen here; only Regula's own liveness screen opens
/// full-screen above the sheet.
class DocumentSheetStep extends ConsumerStatefulWidget {
  final DocumentType type;

  /// What the progress tag names: the request, or the card being added.
  final IssueSheetSubject subject;

  /// The flow's number of steps.
  final int total;

  /// The issuer asks for a face check: it is a step more (see [total]).
  final VoidCallback onFaceCheck;

  /// Back from the instruction, to the details.
  final VoidCallback onBack;

  /// The chip screen's own cancel, already confirmed there.
  final VoidCallback onStopped;

  /// Changed: back from adding the document, the chip screen starts over to
  /// read it again.
  final int readAgain;

  const DocumentSheetStep({
    super.key,
    required this.type,
    required this.subject,
    this.total = 5,
    required this.onBack,
    required this.onStopped,
    required this.onFaceCheck,
    this.readAgain = 0,
  });

  @override
  ConsumerState<DocumentSheetStep> createState() => _DocumentSheetStepState();
}

class _DocumentSheetStepState extends ConsumerState<DocumentSheetStep>
    implements GlassSheetInnerSwipe {
  final _navigator = GlobalKey<NavigatorState>();

  /// The screen on top of the navigator.
  _SheetScreenRoute<dynamic>? _top;

  /// The screen a back swipe is taking away.
  _SheetScreenRoute<dynamic>? _swiping;

  /// Under the instruction, so popping the instruction is noticed and
  /// leaves the flow.
  final _root = PageRouteBuilder<void>(
    pageBuilder: (_, _, _) => const SizedBox.shrink(),
  );
  late final _observer = _ScreenObserver(
    root: _root,
    onScreen: (route) {
      _top = route;
      // Another screen on top (or the chip screen anew): no longer waiting.
      if (mounted) _preparing.value = false;
      if (mounted && route.screen != _screen) {
        setState(() => _screen = route.screen);
      }
    },
    onRoot: () => widget.onBack(),
    // A new screen starts with an empty slot in the bar: it puts its own
    // way on there, or has none.
    onPush: () {
      final context = _navigator.currentContext;
      if (context != null) SheetActionSlot.maybeOf(context)?.set(null);
    },
  );

  /// The screen on top, for the bar's title and the progress.
  _Screen _screen = _Screen.instruction;

  /// The chip screen is open: the camera reports a read more than once.
  var _reading = false;

  /// The chip screen waits for the issuer after the face check: the bar
  /// says the data is being fetched.
  final _preparing = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _preparing.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _preparing.dispose();
    super.dispose();
  }

  /// The chip screen, while it is in the navigator.
  _SheetScreenRoute<void>? _chip;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A swipe back goes back a screen here, not to the details.
    GlassSheetPages.setInnerSwipe(context, this);
  }

  @override
  void didUpdateWidget(DocumentSheetStep old) {
    super.didUpdateWidget(old);
    if (widget.readAgain != old.readAgain) _chipAgain();
  }

  // Past the instruction a swipe takes the screen on top away, as back
  // does; the instruction itself goes back to the details (the sheet's).
  @override
  bool get enabled {
    final top = _top;
    return top != null &&
        top.screen != _Screen.instruction &&
        top.popGestureEnabled;
  }

  @override
  void start() => (_swiping = _top)?.dragStart();

  @override
  void update(double delta) => _swiping?.dragUpdate(delta);

  @override
  void end(double velocity) {
    _swiping?.dragEnd(velocity);
    _swiping = null;
  }

  /// The chip screen anew, to read the document again (back from adding
  /// it): the screens after it go, the chip screen starts over.
  void _chipAgain() {
    final chip = _chip;
    final mrz = chip?.mrz;
    final navigator = _navigator.currentState;
    if (chip == null || mrz == null || !chip.isActive || navigator == null) {
      return;
    }
    navigator
      ..popUntil((route) => route == chip)
      ..replace(oldRoute: chip, newRoute: _chipRoute(mrz, animate: false));
  }

  /// The chip screen for [mrz]; while it is open the camera's reads are
  /// ignored.
  _SheetScreenRoute<void> _chipRoute(ScannedMrz mrz, {bool animate = true}) {
    _reading = true;
    final route = _chip = _SheetScreenRoute<void>(
      _Screen.chip,
      (_) => _nfc(mrz),
      animate: animate,
      mrz: mrz,
    );
    route.popped.whenComplete(() {
      if (_chip != route) return;
      _reading = false;
      _chip = null;
    });
    return route;
  }

  Widget _nfc(ScannedMrz mrz) => DocumentFlowSteps.nfc(
    mrz,
    onCancel: widget.onStopped,
    faceIntro: _faceIntro,
  );

  Future<T?>? _push<T>(_Screen screen, WidgetBuilder builder) =>
      _navigator.currentState?.push<T>(_SheetScreenRoute<T>(screen, builder));

  /// Back in the bar: a screen back, or from the instruction to the details.
  void _back() {
    if (_screen == _Screen.instruction) {
      widget.onBack();
    } else {
      _navigator.currentState?.maybePop();
    }
  }

  /// Start on the instruction: the camera, or typing it in on a device
  /// without one.
  void _capture() {
    if (ref.read(ocrProcessorProvider) == null) {
      _push<void>(_Screen.manual, (_) => _manual());
    } else {
      _push<void>(
        _Screen.reader,
        (_) => DocumentFlowSteps.reader(
          widget.type,
          onRead: _read,
          onManual: () => _push<void>(_Screen.manual, (_) => _manual()),
          onCancel: _back,
        ),
      );
    }
  }

  Widget _manual() => DocumentFlowSteps.manualEntry(
    widget.type,
    onRead: _read,
    onCancel: _back,
  );

  void _read(ScannedMrz mrz) {
    if (_reading) return;
    _navigator.currentState?.push(_chipRoute(mrz));
  }

  /// The face check's intro as the next screen in the sheet; back (or "not
  /// now") is no.
  Future<bool> _faceIntro(BuildContext _) async {
    widget.onFaceCheck();
    final start = await _push<bool>(
      _Screen.face,
      (context) => FaceVerificationIntroScreen(
        onStart: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
    return start ?? false;
  }

  String get _titleKey => _preparing.value
      ? "face_verification.preparing_title"
      : switch (_screen) {
          _Screen.instruction ||
          _Screen.reader ||
          _Screen.manual => widget.type.scanTitleKey,
          _Screen.chip => widget.type.scanTitleKey.replaceFirst(
            ".scan.title",
            ".nfc.title",
          ),
          _Screen.face => "face_verification.title",
        };

  @override
  Widget build(BuildContext context) {
    return GlassSheetPage(
      // Left by dragging its header down: no close button.
      closable: false,
      title: FlutterI18n.translate(context, _titleKey),
      onBack: _back,
      pinned: IssueSheetProgress(
        subject: widget.subject,
        step: _screen.step,
        total: widget.total,
      ),
      subtitle: IssueSheetRequestorLine(subject: widget.subject),
      // The screens fill the page; upright their buttons are in the page's
      // bottom bar, which stays put while they change.
      scrolls: false,
      childClearsBottom: true,
      slotBottom: true,
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: DocumentStepInSheet(
          preparing: _preparing,
          // System back steps back in the flow first; closing the sheet
          // leaves the screens as they are while it goes.
          child: NavigatorPopHandler(
            onPopWithResult: (_) {
              if (!glassSheetClosing(context)) _back();
            },
            // A container of its own: its routes block the semantics of
            // what was painted before them, which would otherwise include the
            // sheet's bar (title, back, close) for screen readers.
            child: Semantics(
              container: true,
              explicitChildNodes: true,
              child: Navigator(
                key: _navigator,
                observers: [_observer],
                onGenerateInitialRoutes: (_, _) => [
                  _root,
                  _SheetScreenRoute<void>(
                    _Screen.instruction,
                    (_) => DocumentFlowSteps.instruction(
                      widget.type,
                      onStart: _capture,
                      onCancel: _back,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A document screen in the sheet: it slides in from the right over the
/// one before, which moves a third of the way left, as the sheet's own pages
/// do. While it moves it has the sheet's colour behind it; once in, the
/// sheet's glass shows through.
class _SheetScreenRoute<T> extends PageRoute<T> {
  final _Screen screen;
  final WidgetBuilder builder;

  /// False: in place at once (a screen started over in its own place).
  final bool animate;

  /// What the chip screen reads with.
  final ScannedMrz? mrz;

  _SheetScreenRoute(this.screen, this.builder, {this.animate = true, this.mrz});

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
      animate ? const Duration(milliseconds: 340) : Duration.zero;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => builder(context);

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

/// Follows the document step's navigator: which screen is on top, and when
/// the instruction is popped off (back from the first screen).
class _ScreenObserver extends NavigatorObserver {
  final Route<void> root;
  final ValueChanged<_SheetScreenRoute<dynamic>> onScreen;
  final VoidCallback onRoot;
  final VoidCallback onPush;

  _ScreenObserver({
    required this.root,
    required this.onScreen,
    required this.onRoot,
    required this.onPush,
  });

  void _show(Route<dynamic>? route) {
    if (route is _SheetScreenRoute) {
      // Not during the navigator's own build.
      WidgetsBinding.instance.addPostFrameCallback((_) => onScreen(route));
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // Over another screen (not the first ones, as the navigator starts).
    if (previousRoute is _SheetScreenRoute) onPush();
    _show(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute == root) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onRoot());
    } else {
      _show(previousRoute);
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _show(previousRoute);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _show(newRoute);
}
