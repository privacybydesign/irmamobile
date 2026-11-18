import "dart:async";
import "dart:ui" show SemanticsActionEvent, SemanticsActionEventCallback;

import "package:flutter/services.dart";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../models/enrollment_status.dart";
import "../providers/irma_repository_provider.dart";

/// Locks the app when it has been backgrounded for longer than
/// [idleThreshold], or left open and untouched for longer than
/// [foregroundIdleThreshold]. The `LockGate` widget reacts to the locked state
/// stream and overlays `PinScreen` on top of whatever route is mounted
/// — no navigation is needed here.
///
/// The foreground timer covers a phone that is put down unlocked with Yivi
/// open: without it the wallet stays open for as long as the screen stays on.
/// Any use of the app restarts it: a touch, scrolling with a mouse wheel or a
/// trackpad, a key press (a keyboard, a D-pad or a switch that types keys),
/// typing on the on-screen keyboard, and an action of a screen reader or
/// another assistive technology, which activate controls without touching them.
///
/// Leaving the app does not restart it: the time that was left when the app
/// went to the background is what is left when it comes back, so short trips
/// to another app cannot postpone the lock for ever.
///
/// Tracks `paused` and `resumed` lifecycle events. `inactive` and `hidden` are
/// intentionally ignored: only a real backgrounding sets `_lastPausedAt`, so
/// transient interruptions (Apple Pay, brief Control Center pulls) cannot
/// trigger a lock.
class IdleLockObserver extends ConsumerStatefulWidget {
  final Widget child;
  final Duration idleThreshold;
  final Duration foregroundIdleThreshold;

  const IdleLockObserver({
    super.key,
    required this.child,
    this.idleThreshold = const Duration(minutes: 5),
    this.foregroundIdleThreshold = const Duration(minutes: 5),
  });

  @override
  ConsumerState<IdleLockObserver> createState() => _IdleLockObserverState();
}

class _IdleLockObserverState extends ConsumerState<IdleLockObserver>
    with WidgetsBindingObserver {
  DateTime? _lastPausedAt;
  Timer? _foregroundIdleTimer;

  /// When the running foreground timer was started, to know how much of it is
  /// left when the app goes to the background.
  DateTime _foregroundIdleSince = DateTime.now();

  /// What was left of the foreground timer when the app went to the background.
  Duration? _foregroundIdleLeftAtPause;

  /// The controller of the text field that has the focus, if one has.
  TextEditingController? _focusedTextController;

  /// The framework's handler for actions of assistive technologies, which
  /// [_onSemanticsAction] stands in front of while this widget is mounted.
  SemanticsActionEventCallback? _frameworkSemanticsActionHandler;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HardwareKeyboard.instance.addHandler(_onKeyEvent);
    // TalkBack, VoiceOver, Switch Access and Voice Access activate a control
    // with a semantics action, which is neither a pointer nor a key event. The
    // framework has no listener for those, so this sees them on their way in
    // and passes every one of them on untouched.
    final dispatcher = WidgetsBinding.instance.platformDispatcher;
    _frameworkSemanticsActionHandler = dispatcher.onSemanticsActionEvent;
    dispatcher.onSemanticsActionEvent = _onSemanticsAction;
    // Typing on the on-screen keyboard arrives as an edit of the focused text
    // field, not as key events, so the field that has the focus is watched.
    FocusManager.instance.addListener(_onFocusChange);
    _restartForegroundIdleTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    final dispatcher = WidgetsBinding.instance.platformDispatcher;
    // Only put the framework's handler back when ours is still the one in
    // place; someone who replaced it since is not ours to undo.
    if (dispatcher.onSemanticsActionEvent == _onSemanticsAction) {
      dispatcher.onSemanticsActionEvent = _frameworkSemanticsActionHandler;
    }
    FocusManager.instance.removeListener(_onFocusChange);
    _focusedTextController?.removeListener(_restartForegroundIdleTimer);
    _foregroundIdleTimer?.cancel();
    super.dispose();
  }

  void _onFocusChange() {
    final controller = FocusManager.instance.primaryFocus?.context
        ?.findAncestorWidgetOfExactType<EditableText>()
        ?.controller;
    if (controller == _focusedTextController) return;
    _focusedTextController?.removeListener(_restartForegroundIdleTimer);
    _focusedTextController = controller;
    controller?.addListener(_restartForegroundIdleTimer);
  }

  /// Never handles the key: it only notes that the app is being used.
  bool _onKeyEvent(KeyEvent event) {
    _restartForegroundIdleTimer();
    return false;
  }

  void _onSemanticsAction(SemanticsActionEvent action) {
    _restartForegroundIdleTimer();
    _frameworkSemanticsActionHandler?.call(action);
  }

  void _restartForegroundIdleTimer() =>
      _startForegroundIdleTimer(widget.foregroundIdleThreshold);

  void _startForegroundIdleTimer(Duration left) {
    _foregroundIdleTimer?.cancel();
    // Kept as if the timer had started a full threshold before it ends, so
    // what is left can be worked out from it at any moment.
    _foregroundIdleSince = DateTime.now().subtract(
      widget.foregroundIdleThreshold - left,
    );
    _foregroundIdleTimer = Timer(left, () {
      // Start counting again right away: an unlock with biometrics does not
      // touch the app, so nothing else would restart the timer after it.
      _restartForegroundIdleTimer();
      _lock();
    });
  }

  Future<void> _lock() async {
    final repo = ref.read(irmaRepositoryProvider);
    final status = await repo.getEnrollmentStatus().firstWhere(
      (s) => s != EnrollmentStatus.undetermined,
    );
    if (!mounted) return;
    if (status != EnrollmentStatus.enrolled) return;

    if (await repo.getLocked().first) return;
    if (!mounted) return;

    repo.lock();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      final now = DateTime.now();
      // In the background the paused timestamp takes over. A second `paused`
      // without a resume in between has no running timer to read.
      if (_foregroundIdleTimer?.isActive ?? false) {
        final left =
            widget.foregroundIdleThreshold -
            now.difference(_foregroundIdleSince);
        _foregroundIdleLeftAtPause = left.isNegative ? Duration.zero : left;
      }
      _lastPausedAt = now;
      _foregroundIdleTimer?.cancel();
      return;
    }
    if (state != AppLifecycleState.resumed) return;

    // Without a pause the app was only briefly inactive and the timer kept
    // running.
    final pausedAt = _lastPausedAt;
    _lastPausedAt = null;
    if (pausedAt == null) return;

    if (DateTime.now().difference(pausedAt) > widget.idleThreshold) {
      _restartForegroundIdleTimer();
      await _lock();
      return;
    }
    // Coming back is not use of the app: go on with what was left.
    _startForegroundIdleTimer(
      _foregroundIdleLeftAtPause ?? widget.foregroundIdleThreshold,
    );
  }

  @override
  Widget build(BuildContext context) => Listener(
    // Sees every pointer that goes down anywhere in the app, without taking
    // part in the gesture arena. A mouse wheel and a trackpad scroll without a
    // pointer going down.
    behavior: HitTestBehavior.translucent,
    onPointerDown: (_) => _restartForegroundIdleTimer(),
    onPointerSignal: (_) => _restartForegroundIdleTimer(),
    onPointerPanZoomStart: (_) => _restartForegroundIdleTimer(),
    child: widget.child,
  );
}
