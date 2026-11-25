import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";

import "../../providers/preferences_provider.dart";
import "../../routing/navigation.dart";
import "../../theme/yivi_motion.dart";
import "../../theme/yivi_palette.dart";
import "../../theme/yivi_space.dart";
import "../../util/i18n.dart";
import "../../widgets/feedback/spinner.dart";
import "../../widgets/text/translated_text.dart";
import "biometric/enrollment_biometric_screen.dart";
import "choose_pin/choose_pin_screen.dart";
import "confirm_pin/confirm_pin_screen.dart";
import "confirm_pin/widgets/pin_confirmation_failed_dialog.dart";
import "enrollment_failed_screen.dart";
import "enrollment_provider.dart";
import "enrollment_state.dart";
import "terms/enrollment_terms_screen.dart";
import "welcome/welcome_screen.dart";
import "widgets/enrollment_bar.dart";
import "widgets/wallet_deleted_confirmation.dart";

class EnrollmentScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends ConsumerState<EnrollmentScreen> {
  /// The PIN chosen in the first step, for the confirm step to compare
  /// with. Kept here, not in build: anything that rebuilds the screen
  /// between the two steps (a theme change) would otherwise forget it.
  final _newPin = ValueNotifier("");

  final _navigator = GlobalKey<NavigatorState>();

  /// Goes up after a second PIN that did not match, so choosing starts over
  /// on a fresh PIN page.
  var _chooseRound = 0;

  @override
  void initState() {
    super.initState();
    // The default for this value is intentionally
    // different for the fresh install and upgrade flows.
    ref.read(preferencesProvider).longPin.set(false);
  }

  @override
  void dispose() {
    _newPin.dispose();
    super.dispose();
  }

  Future<void> _onEnrollmentCompleted(BuildContext context) async {
    // The empty Data tab points out the Scan button on the first visit.
    await ref.read(preferencesProvider).scanTipPending.set(true);
    // LockGate handles displaying the PIN overlay if the app is still
    // locked after enrollment.
    if (context.mounted) context.goHomeScreen();
  }

  String _step(BuildContext context, EnrollmentStepNumber step) => context.tr(
    "enrollment.step",
    {"current": "${step.number}", "total": "${step.total}"},
  );

  /// How far into the steps [state] is: the pages up to it are stacked, so
  /// each step is pushed over the one before and back pops it.
  static int _depth(EnrollmentState state) => switch (state) {
    EnrollmentWelcome() => 0,
    EnrollmentTerms() => 1,
    EnrollmentChoosePin() => 2,
    EnrollmentConfirmPin() => 3,
    EnrollmentBiometric() => 4,
    // Setting up or failed: over the last step.
    _ => 5,
  };

  static const _keys = [
    ValueKey("welcome"),
    ValueKey("terms"),
    ValueKey("choose_pin"),
    ValueKey("confirm_pin"),
    ValueKey("biometric"),
  ];

  /// The step a back swipe or the system back button may leave: the terms
  /// and the two PIN pages. Face ID can't go back (the account is being
  /// made), nor can setting up.
  static bool _canGoBack(EnrollmentState state) =>
      state is EnrollmentTerms ||
      state is EnrollmentChoosePin ||
      state is EnrollmentConfirmPin;

  List<Page<Object?>> _pages(BuildContext context, EnrollmentState state) {
    final enrollment = ref.read(enrollmentProvider.notifier);
    final depth = _depth(state);
    final space = enrollmentBarHeight + YiviSpace.x8;
    Widget step(Widget child) =>
        EnrollmentBarSpace(height: space, child: child);
    Page<Object?> page(int index, Widget child, {bool canPop = true}) =>
        MaterialPage(
          key: _keys[index],
          child: PopScope(canPop: canPop, child: child),
        );

    return [
      page(
        0,
        WelcomeScreen(
          onContinue: () => enrollment.next(language: context.lang),
        ),
      ),
      if (depth >= 1)
        page(
          1,
          step(
            EnrollmentTermsScreen(
              // Below the PIN the terms were accepted to get there.
              isAccepted: state is EnrollmentTerms ? state.isAccepted : true,
              onContinue: enrollment.termsAccepted,
              onToggleAccepted: (isAccepted) {
                ref.read(preferencesProvider).acceptLatestTerms(isAccepted);
                enrollment.setTermsAccepted(isAccepted);
              },
            ),
          ),
          canPop: state is EnrollmentTerms,
        ),
      if (depth >= 2)
        page(
          2,
          step(
            KeyedSubtree(
              key: ValueKey(_chooseRound),
              child: ChoosePinScreen(
                underBar: true,
                onPrevious: enrollment.back,
                onChoosePin: enrollment.pinChosen,
                newPinNotifier: _newPin,
              ),
            ),
          ),
          canPop: state is EnrollmentChoosePin,
        ),
      if (depth >= 3)
        page(
          3,
          step(
            ConfirmPinScreen(
              underBar: true,
              newPinNotifier: _newPin,
              onPrevious: enrollment.back,
              submitConfirmationPin: enrollment.pinConfirmed,
              onPinMismatch: () {
                showPinConfirmationFailedDialog(
                  context,
                  onPressed: (context) {
                    setState(() => _chooseRound++);
                    enrollment.pinMismatch();
                    context.pop();
                  },
                );
              },
            ),
          ),
          canPop: state is EnrollmentConfirmPin,
        ),
      if (depth >= 4 && state is! EnrollmentFailed)
        page(
          4,
          step(EnrollmentBiometricScreen(onDone: enrollment.biometricDone)),
          canPop: false,
        ),
      if (state case EnrollmentFailed())
        _FadePage(
          key: const ValueKey("failed"),
          child: PopScope(
            canPop: false,
            child: EnrollmentFailedScreen(
              onPrevious: enrollment.back,
              onRetryEnrollment: enrollment.retry,
            ),
          ),
        )
      else if (depth >= 5)
        // Waiting for the account after the last step: the logo, a spinner
        // and "Setting up your app".
        _FadePage(
          key: const ValueKey("setting_up"),
          child: PopScope(
            canPop: false,
            child: _SettingUp(showText: state is Enrolling),
          ),
        ),
    ];
  }

  /// A page went. When it is the step on screen, the user went back (a back
  /// swipe, or the system back button): the enrollment follows. Pages the
  /// enrollment itself takes away need nothing.
  void _removed(Page<Object?> page) {
    final state = ref.read(enrollmentProvider);
    final depth = _depth(state);
    if (depth < _keys.length && page.key == _keys[depth] && _canGoBack(state)) {
      ref.read(enrollmentProvider.notifier).back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final enrollment = ref.read(enrollmentProvider.notifier);
    ref.listen(enrollmentProvider, (_, state) {
      if (state is EnrollmentCompleted) _onEnrollmentCompleted(context);
    });
    final state = ref.watch(enrollmentProvider);
    final step = switch (state) {
      EnrollmentTerms(:final step) => step,
      EnrollmentChoosePin(:final step) => step,
      EnrollmentConfirmPin(:final step) => step,
      EnrollmentBiometric(:final step) => step,
      _ => null,
    };

    return WalletDeletedConfirmation(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        // AnnotatedRegion replaces the whole style; the theme's has readable
        // bar icons for the current brightness (Android 15+ keeps only those).
        value:
            Theme.of(context).appBarTheme.systemOverlayStyle ??
            (YiviPalette.of(context).isDark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark),
        child: Stack(
          children: [
            // The system back button goes back a step, as the bar's does.
            NavigatorPopHandler(
              enabled: _canGoBack(state),
              onPopWithResult: (_) => _navigator.currentState?.maybePop(),
              child: HeroControllerScope(
                controller: MaterialApp.createMaterialHeroController(),
                child: Navigator(
                  key: _navigator,
                  pages: _pages(context, state),
                  onDidRemovePage: _removed,
                ),
              ),
            ),
            // Over the pages, so it stays put while they slide under it.
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: EnrollmentBar(
                step: step,
                label: step == null ? "" : _step(context, step),
                onBack: _canGoBack(state) ? enrollment.back : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A page that fades in over the steps (setting up, a failure) instead of
/// sliding: it is not a step.
class _FadePage extends Page<void> {
  final Widget child;

  const _FadePage({super.key, required this.child});

  @override
  Route<void> createRoute(BuildContext context) => PageRouteBuilder<void>(
    settings: this,
    transitionDuration: YiviMotion.standard,
    reverseTransitionDuration: YiviMotion.standard,
    pageBuilder: (context, _, _) => child,
    transitionsBuilder: (context, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

class _SettingUp extends StatelessWidget {
  final bool showText;

  const _SettingUp({required this.showText});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Scaffold(
      backgroundColor: palette.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: YiviSpace.x48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: SvgPicture.asset(
                  YiviPalette.of(context).logoAsset,
                  height: 52,
                ),
              ),
              const SizedBox(height: YiviSpace.x48),
              Spinner(),
              if (showText) ...[
                const SizedBox(height: YiviSpace.x24),
                TranslatedText(
                  "enrollment.setting_up",
                  isHeader: true,
                  textAlign: TextAlign.center,
                  style: palette.titleSmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
