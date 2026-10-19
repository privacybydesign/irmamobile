import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:vcmrtd/vcmrtd.dart";

import "../../../models/mrz.dart";
import "../../../providers/ocr_processor_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../widgets/glass/glass_sheet.dart";
import "../../session/widgets/issue_sheet_progress.dart";
import "document_flow_steps.dart";
import "document_step_in_sheet.dart";
import "document_translation_keys.dart";
import "face_verification_intro_screen.dart";

/// Which document issues [credentialId] (`pbdf.pbdf.passport` and its
/// staging twin, and so on), if any.
DocumentType? documentTypeOf(String credentialId) =>
    switch (credentialId.split(".").last) {
      "passport" => .passport,
      "idcard" => .identityCard,
      "drivinglicence" => .drivingLicence,
      _ => null,
    };

/// The screens of adding a document, and the step of the sheet's progress
/// each one is.
enum _Screen {
  instruction(2),
  reader(3),
  manual(3),
  chip(4),
  face(4);

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

  /// Back from the instruction, to the details.
  final VoidCallback onBack;

  /// The chip screen's own cancel, already confirmed there.
  final VoidCallback onStopped;

  const DocumentSheetStep({
    super.key,
    required this.type,
    required this.subject,
    this.total = 5,
    required this.onBack,
    required this.onStopped,
  });

  @override
  ConsumerState<DocumentSheetStep> createState() => _DocumentSheetStepState();
}

class _DocumentSheetStepState extends ConsumerState<DocumentSheetStep> {
  final _navigator = GlobalKey<NavigatorState>();

  /// Under the instruction, so popping the instruction is noticed and
  /// leaves the flow.
  final _root = PageRouteBuilder<void>(
    pageBuilder: (_, _, _) => const SizedBox.shrink(),
  );
  late final _observer = _ScreenObserver(
    root: _root,
    onScreen: (screen) {
      if (mounted && screen != _screen) setState(() => _screen = screen);
    },
    onRoot: () => widget.onBack(),
  );

  /// The screen on top, for the bar's title and the progress.
  _Screen _screen = _Screen.instruction;

  /// The chip screen is open: the camera reports a read more than once.
  var _reading = false;

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
    _reading = true;
    _push<void>(
      _Screen.chip,
      (_) => DocumentFlowSteps.nfc(
        mrz,
        onCancel: widget.onStopped,
        faceIntro: _faceIntro,
      ),
    )?.whenComplete(() => _reading = false);
  }

  /// The face check's intro as the next screen in the sheet; back (or "not
  /// now") is no.
  Future<bool> _faceIntro(BuildContext _) async {
    final start = await _push<bool>(
      _Screen.face,
      (context) => FaceVerificationIntroScreen(
        onStart: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
    return start ?? false;
  }

  String get _titleKey => switch (_screen) {
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
      title: FlutterI18n.translate(context, _titleKey),
      onBack: _back,
      pinned: IssueSheetProgress(
        subject: widget.subject,
        step: _screen.step,
        total: widget.total,
      ),
      // The screens fill the page and have their own buttons at the bottom.
      scrolls: false,
      childClearsBottom: true,
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: DocumentStepInSheet(
          // System back steps back in the flow first.
          child: NavigatorPopHandler(
            onPopWithResult: (_) => _back(),
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

  _SheetScreenRoute(this.screen, this.builder);

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 340);

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
    final curve = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
    if (MediaQuery.disableAnimationsOf(context)) {
      return FadeTransition(opacity: curve, child: child);
    }
    final behind = CurvedAnimation(
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
  final ValueChanged<_Screen> onScreen;
  final VoidCallback onRoot;

  _ScreenObserver({
    required this.root,
    required this.onScreen,
    required this.onRoot,
  });

  void _show(Route<dynamic>? route) {
    if (route is _SheetScreenRoute) {
      final screen = route.screen;
      // Not during the navigator's own build.
      WidgetsBinding.instance.addPostFrameCallback((_) => onScreen(screen));
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _show(route);

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
