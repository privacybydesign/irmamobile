import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../routing/navigation.dart";
import "../../util/i18n.dart";
import "../../widgets/bars/app_bar.dart";
import "../../widgets/feedback/app_toast.dart";
import "../../widgets/feedback/dialog.dart";
import "../error/session_error_screen.dart";
import "../pin/pin_entry.dart";
import "../pin/yivi_pin_screen.dart";
import "change_pin_flow.dart";

/// Change PIN: its pages follow the step ([changePinFlowProvider]) in a
/// navigator of their own, so they slide as before and confirm can be
/// swiped back to choose. Nothing pushes or pops by name.
class ChangePinScreen extends ConsumerStatefulWidget {
  const ChangePinScreen({super.key});

  @override
  ConsumerState<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends ConsumerState<ChangePinScreen> {
  /// The pages of the last step that had pages (blocked and done have
  /// none of their own: the screen goes).
  List<Page<void>> _pages = const [];

  ChangePinFlow get _flow => ref.read(changePinFlowProvider.notifier);

  List<Page<void>>? _pagesOf(ChangePinStep step) => switch (step) {
    // Keyed by the wrong PINs: after one the page slides in again.
    EnterOldPin(:final feedback) && final enter => [
      MaterialPage(
        key: ValueKey("enter#${feedback.wrongCount}"),
        child: _EnterOldPin(step: enter),
      ),
    ],
    // The new PIN, then the same again, on one page: the chosen PIN moves
    // up, grey, and is entered again under it.
    ChooseNewPin(:final round, :final previous) => [
      MaterialPage(
        key: ValueKey("new#$round"),
        child: _NewPin(
          chosen: null,
          previous: previous,
          onBack: context.goSettingsScreen,
          onChosen: _flow.choose,
          onMismatch: _flow.mismatch,
          onConfirmed: _confirm,
        ),
      ),
    ],
    ConfirmNewPin(:final chosen, :final choose) => [
      MaterialPage(
        key: ValueKey("new#${choose.round}"),
        child: _NewPin(
          chosen: chosen,
          previous: choose.previous,
          onBack: _flow.backToChoose,
          onChosen: _flow.choose,
          onMismatch: _flow.mismatch,
          onConfirmed: _confirm,
        ),
      ),
    ],
    ChangePinFailed(:final error, :final back) => [
      ...?_pagesOf(back),
      MaterialPage(
        key: const ValueKey("error"),
        child: SessionErrorScreen(error: error, onTapClose: _flow.closeError),
      ),
    ],
    ChangePinBlocked() || ChangePinDone() => null,
  };

  Future<void> _confirm(String pin) async {
    final confirmed = await showConfirmDialog(
      context,
      icon: const ToneDisc(icon: Icons.password_rounded),
      titleKey: "change_pin.dialog.title",
      messageKey: "change_pin.dialog.body",
      confirmKey: "change_pin.dialog.ok",
      cancelKey: "change_pin.dialog.cancel",
    );
    if (!mounted) return;
    if (confirmed) {
      _flow.commit(pin);
    } else {
      context.goSettingsScreen();
    }
  }

  /// A page went (a back swipe or the back button): the step follows.
  void _removed(Page<Object?> page) {
    final key = page.key;
    if (key == const ValueKey("confirm")) {
      _flow.backToChoose();
    } else if (key == const ValueKey("error")) {
      _flow.closeError();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(changePinFlowProvider, (_, step) {
      switch (step) {
        case ChangePinDone():
          context.goSettingsScreen();
          showAppToast(context, context.tr("change_pin.toast"));
        case ChangePinBlocked():
          context.goHomeScreenWithoutTransition();
        default:
          break;
      }
    });
    final pages = _pagesOf(ref.watch(changePinFlowProvider));
    if (pages != null) _pages = pages;

    return HeroControllerScope(
      controller: MaterialApp.createMaterialHeroController(),
      child: Navigator(pages: _pages, onDidRemovePage: _removed),
    );
  }
}

/// The current PIN; after a wrong one it says how many tries are left.
class _EnterOldPin extends ConsumerWidget {
  final EnterOldPin step;

  const _EnterOldPin({required this.step});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return YiviPinScaffold(
      appBar: YiviAppBar(
        titleString: "",
        leading: YiviBackButton(onTap: context.goSettingsScreen),
      ),
      body: PinEntry(
        mode: const VerifyOldEntry(),
        feedback: step.feedback,
        onSubmit: ref.read(changePinFlowProvider.notifier).submitOld,
      ),
    );
  }
}

/// The new PIN ([chosen] null), then the same again on the same screen.
/// Back while entering it again goes back to choosing, here.
class _NewPin extends StatelessWidget {
  final String? chosen;
  final String previous;
  final VoidCallback onBack;
  final ValueChanged<String> onChosen;
  final VoidCallback onMismatch;
  final ValueChanged<String> onConfirmed;

  const _NewPin({
    required this.chosen,
    required this.previous,
    required this.onBack,
    required this.onChosen,
    required this.onMismatch,
    required this.onConfirmed,
  });

  @override
  Widget build(BuildContext context) {
    final chosen = this.chosen;
    return PopScope(
      canPop: chosen == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onBack();
      },
      child: YiviPinScaffold(
        appBar: YiviAppBar(
          titleString: "",
          leading: YiviBackButton(onTap: onBack),
        ),
        body: PinEntry(
          mode: chosen == null
              ? ChooseEntry(previous: previous)
              : ConfirmEntry(
                  chosen: chosen,
                  instructionKey: "choose_pin.again",
                  onMismatch: onMismatch,
                  inPlace: true,
                ),
          onSubmit: chosen == null ? onChosen : onConfirmed,
        ),
      ),
    );
  }
}
