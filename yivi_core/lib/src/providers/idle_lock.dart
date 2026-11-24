import "dart:async";
import "dart:ui" show SemanticsActionEvent, SemanticsActionEventCallback;

import "package:flutter/services.dart";
import "package:material_ui/material_ui.dart";

/// Locks the app after it was left alone: in the background for longer than
/// [background], or open and untouched for longer than [foreground].
///
/// The foreground timer covers a phone that is put down unlocked with Yivi
/// open: without it the wallet stays open for as long as the screen stays on.
/// Any use of the app restarts it ([noteUse]): a touch, scrolling with a mouse
/// wheel or a trackpad ([IdleUseListener]), a key press (a keyboard, a D-pad or
/// a switch that types keys), typing on the on-screen keyboard, and an action
/// of a screen reader or another assistive technology, which activate controls
/// without touching them.
///
/// Leaving the app does not restart it: the time that was left when the app
/// went to the background is what is left when it comes back, so short trips
/// to another app cannot postpone the lock for ever.
///
/// Only `paused` and `resumed` count as leaving and coming back: `inactive`
/// and `hidden` alone (Apple Pay, a brief pull of Control Center) are no
/// backgrounding.
class IdleLock {
  IdleLock({
    required this.background,
    required this.foreground,
    required Future<void> Function() lock,
  }) : _lock = lock {
    _lifecycle = AppLifecycleListener(onStateChange: _onStateChange);
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
    noteUse();
  }

  final Duration background;
  final Duration foreground;

  /// Locks the app, when there is a wallet to lock and it is not locked yet.
  final Future<void> Function() _lock;

  late final AppLifecycleListener _lifecycle;
  SemanticsActionEventCallback? _frameworkSemanticsActionHandler;
  TextEditingController? _focusedTextController;

  Timer? _foregroundTimer;

  /// When the running foreground timer was started, to know how much of it is
  /// left when the app goes to the background.
  DateTime _foregroundSince = DateTime.now();

  /// What was left of the foreground timer when the app went to the
  /// background.
  Duration? _foregroundLeftAtPause;

  DateTime? _pausedAt;

  /// The app was used: the foreground timer starts again.
  void noteUse() => _startForeground(foreground);

  void _startForeground(Duration left) {
    _foregroundTimer?.cancel();
    // Kept as if the timer had started a full threshold before it ends, so
    // what is left can be worked out from it at any moment.
    _foregroundSince = DateTime.now().subtract(foreground - left);
    _foregroundTimer = Timer(left, () {
      // Start counting again right away: an unlock with biometrics does not
      // touch the app, so nothing else would restart the timer after it.
      noteUse();
      _lock();
    });
  }

  void _onStateChange(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        final now = DateTime.now();
        // In the background the paused timestamp takes over. A second
        // `paused` without a resume in between has no running timer to read.
        if (_foregroundTimer?.isActive ?? false) {
          final left = foreground - now.difference(_foregroundSince);
          _foregroundLeftAtPause = left.isNegative ? Duration.zero : left;
        }
        _pausedAt = now;
        _foregroundTimer?.cancel();
      case AppLifecycleState.resumed:
        // Without a pause the app was only briefly inactive and the timer
        // kept running.
        final pausedAt = _pausedAt;
        _pausedAt = null;
        if (pausedAt == null) return;
        if (DateTime.now().difference(pausedAt) > background) {
          noteUse();
          _lock();
          return;
        }
        // Coming back is not use of the app: go on with what was left.
        _startForeground(_foregroundLeftAtPause ?? foreground);
      default:
    }
  }

  void _onFocusChange() {
    final controller = FocusManager.instance.primaryFocus?.context
        ?.findAncestorWidgetOfExactType<EditableText>()
        ?.controller;
    if (controller == _focusedTextController) return;
    _focusedTextController?.removeListener(noteUse);
    _focusedTextController = controller;
    controller?.addListener(noteUse);
  }

  /// Never handles the key: it only notes that the app is being used.
  bool _onKeyEvent(KeyEvent event) {
    noteUse();
    return false;
  }

  void _onSemanticsAction(SemanticsActionEvent action) {
    noteUse();
    _frameworkSemanticsActionHandler?.call(action);
  }

  void dispose() {
    _lifecycle.dispose();
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    final dispatcher = WidgetsBinding.instance.platformDispatcher;
    // Only put the framework's handler back when ours is still the one in
    // place; someone who replaced it since is not ours to undo.
    if (dispatcher.onSemanticsActionEvent == _onSemanticsAction) {
      dispatcher.onSemanticsActionEvent = _frameworkSemanticsActionHandler;
    }
    FocusManager.instance.removeListener(_onFocusChange);
    _focusedTextController?.removeListener(noteUse);
    _foregroundTimer?.cancel();
  }
}

/// Tells [onUse] about every pointer that goes down anywhere under it,
/// without taking part in the gesture arena, and about scrolling with a mouse
/// wheel or a trackpad, which moves no pointer down.
class IdleUseListener extends StatelessWidget {
  final VoidCallback onUse;
  final Widget child;

  const IdleUseListener({super.key, required this.onUse, required this.child});

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (_) => onUse(),
    onPointerSignal: (_) => onUse(),
    onPointerPanZoomStart: (_) => onUse(),
    child: child,
  );
}
