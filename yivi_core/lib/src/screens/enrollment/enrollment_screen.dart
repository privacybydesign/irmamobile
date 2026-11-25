import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../providers/preferences_provider.dart";
import "../../routing/navigation.dart";
import "../../theme/yivi_motion.dart";
import "../../theme/yivi_palette.dart";
import "../../theme/yivi_space.dart";
import "../../util/i18n.dart";
import "../../widgets/sheet/sheet.dart";
import "../pin/providers/biometric_provider.dart";
import "biometric/enrollment_biometric_screen.dart";
import "done/enrollment_done_page.dart";
import "enrollment_failed_screen.dart";
import "enrollment_provider.dart";
import "enrollment_state.dart";
import "error_reports/enrollment_error_reports_screen.dart";
import "pin/enrollment_pin_page.dart";
import "terms/enrollment_terms_screen.dart";
import "welcome/welcome_screen.dart";
import "widgets/enrollment_actions.dart";
import "widgets/enrollment_bar.dart";
import "widgets/enrollment_step_page.dart";
import "widgets/wallet_deleted_confirmation.dart";

class EnrollmentScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends ConsumerState<EnrollmentScreen> {
  /// The PIN chosen in step 3, for step 4 to compare with. Kept here, not in
  /// build: anything that rebuilds the screen between the two (a theme
  /// change) would otherwise forget it.
  String _chosenPin = "";

  final _navigator = GlobalKey<NavigatorState>();
  final _welcome = GlobalKey<WelcomeScreenState>();

  /// Use Face ID waits for the system prompt.
  var _biometricBusy = false;

  @override
  void initState() {
    super.initState();
    // The default for this value is intentionally
    // different for the fresh install and upgrade flows.
    ref.read(preferencesProvider).longPin.set(false);
  }

  var _leaving = false;

  /// Continue on the done page: into the app.
  Future<void> _onEnrollmentCompleted(BuildContext context) async {
    if (_leaving) return;
    _leaving = true;
    // LockGate handles displaying the PIN overlay if the app is still
    // locked after enrollment.
    if (context.mounted) context.goHomeScreen();
  }

  String _step(BuildContext context, EnrollmentStepNumber step) => context.tr(
    "enrollment.step",
    {"current": "${step.number}", "total": "${step.total}"},
  );

  /// How far into the steps [state] is: the pages up to it are stacked, so
  /// each step comes in over the one before and back takes it away. The PIN
  /// is one page, chosen and then entered again on it.
  static int _depth(EnrollmentState state) => switch (state) {
    EnrollmentWelcome() => 0,
    EnrollmentTerms() => 1,
    EnrollmentErrorReports() => 2,
    EnrollmentChoosePin() || EnrollmentConfirmPin() => 3,
    EnrollmentBiometric() => 4,
    // Setting up or failed: over the last step.
    _ => 5,
  };

  static const _keys = [
    ValueKey("welcome"),
    ValueKey("terms"),
    ValueKey("error_reports"),
    ValueKey("pin"),
    ValueKey("biometric"),
  ];

  /// The steps a back swipe or the system back button may leave: the terms,
  /// error reports and choosing the PIN (back while entering it again goes
  /// back to choosing, on the same page). Face ID can't go back (the account
  /// is being made), nor can setting up.
  static bool _canGoBack(EnrollmentState state) =>
      state is EnrollmentTerms ||
      state is EnrollmentErrorReports ||
      state is EnrollmentChoosePin;

  static bool _hasBack(EnrollmentState state) =>
      _canGoBack(state) || state is EnrollmentConfirmPin;

  Future<void> _useBiometric() async {
    setState(() => _biometricBusy = true);
    await ref
        .read(biometricServiceProvider)
        .confirmAndEnable(
          localizedReason: context.tr("pin.biometric_confirm_reason"),
        );
    if (!mounted) return;
    setState(() => _biometricBusy = false);
    ref.read(enrollmentProvider.notifier).biometricDone();
  }

  void _biometricNotNow() {
    ref.read(biometricServiceProvider).dismissPrompt();
    ref.read(enrollmentProvider.notifier).biometricDone();
  }

  /// The buttons of the step at [depth] (null: none, as on the PIN).
  EnrollmentStepActions? _actionsAt(BuildContext context, int depth) {
    final enrollment = ref.read(enrollmentProvider.notifier);
    switch (depth) {
      case 0:
        return EnrollmentStepActions(
          primary: context.tr("enrollment.welcome.start"),
          primaryKey: const Key("enrollment_next_button"),
          onPrimary: () => _welcome.currentState?.start(),
        );
      case 1:
        return EnrollmentStepActions(
          primary: context.tr("enrollment.terms.accept"),
          primaryKey: const Key("enrollment_terms_continue"),
          onPrimary: enrollment.termsAccepted,
        );
      case 2:
        return EnrollmentStepActions(
          primary: context.tr("enrollment.error_reports.share"),
          primaryKey: const Key("error_reports_share"),
          onPrimary: () => enrollment.errorReportsChosen(share: true),
          secondary: context.tr("enrollment.error_reports.dont_share"),
          secondaryKey: const Key("error_reports_dont_share"),
          onSecondary: () => enrollment.errorReportsChosen(share: false),
        );
      case 4:
        final kind = biometricKindOf(ref.watch(biometricTypeProvider).value);
        return EnrollmentStepActions(
          primary: context.tr("enrollment.biometric.use_$kind"),
          primaryKey: const Key("biometric_enable"),
          onPrimary: _biometricBusy ? null : _useBiometric,
          secondary: context.tr("enrollment.biometric.not_now"),
          secondaryKey: const Key("biometric_not_now"),
          onSecondary: _biometricBusy ? null : _biometricNotNow,
        );
      case 5:
        // Done: Continue, into the app, once the account is there.
        if (ref.watch(enrollmentProvider) is! EnrollmentCompleted) return null;
        return EnrollmentStepActions(
          primary: context.tr("ui.continue"),
          primaryKey: const Key("enrollment_continue"),
          onPrimary: () => _onEnrollmentCompleted(context),
        );
      default:
        return null;
    }
  }

  List<Page<Object?>> _pages(BuildContext context, EnrollmentState state) {
    final enrollment = ref.read(enrollmentProvider.notifier);
    final depth = _depth(state);
    final space = enrollmentBarHeight + YiviSpace.x8;
    Widget step(Widget child) =>
        EnrollmentBarSpace(height: space, child: child);
    Page<Object?> page(int index, Widget child, {bool canPop = true}) =>
        EnrollmentStepPage(
          key: _keys[index],
          child: PopScope(
            canPop: canPop,
            // Entering the PIN again: back goes back to choosing, here.
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop && state is EnrollmentConfirmPin && index == 3) {
                enrollment.back();
              }
            },
            child: child,
          ),
        );

    return [
      page(
        0,
        WelcomeScreen(
          key: _welcome,
          onContinue: () => enrollment.next(language: context.lang),
        ),
      ),
      if (depth >= 1)
        page(
          1,
          step(EnrollmentTermsScreen(actions: _actionsAt(context, 1)!)),
          canPop: state is EnrollmentTerms,
        ),
      if (depth >= 2)
        page(
          2,
          step(EnrollmentErrorReportsScreen(actions: _actionsAt(context, 2)!)),
          canPop: state is EnrollmentErrorReports,
        ),
      if (depth >= 3)
        page(
          3,
          step(
            EnrollmentPinPage(
              // Chosen until choosing starts over: confirmed, the page
              // stays as it is while the next comes in.
              chosen: state is EnrollmentChoosePin ? null : _chosenPin,
              onChosen: (pin) {
                _chosenPin = pin;
                enrollment.pinChosen(pin);
              },
              onConfirmed: enrollment.pinConfirmed,
              onMismatch: enrollment.pinMismatch,
            ),
          ),
          canPop: state is EnrollmentChoosePin,
        ),
      if (depth >= 4 && state is! EnrollmentFailed)
        page(
          4,
          step(EnrollmentBiometricScreen(actions: _actionsAt(context, 4)!)),
          canPop: false,
        ),
      if (state case EnrollmentFailed(:final error))
        _FadePage(
          key: const ValueKey("failed"),
          child: PopScope(
            canPop: false,
            child: EnrollmentFailedScreen(
              error: error,
              onPrevious: enrollment.back,
              onRetryEnrollment: enrollment.retry,
            ),
          ),
        )
      else if (depth >= 5)
        // After the last step: the app sets up around the lock from the
        // PIN, then it's done, and Continue goes into the app.
        _FadePage(
          key: const ValueKey("done"),
          duration: const Duration(milliseconds: 560),
          child: PopScope(
            canPop: false,
            child: EnrollmentDonePage(
              ready: state is EnrollmentCompleted,
              actions: _actionsAt(context, 5),
            ),
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
    final state = ref.watch(enrollmentProvider);
    final step = switch (state) {
      EnrollmentTerms(:final step) => step,
      EnrollmentErrorReports(:final step) => step,
      EnrollmentChoosePin(:final step) => step,
      EnrollmentConfirmPin(:final step) => step,
      EnrollmentBiometric(:final step) => step,
      _ => null,
    };
    final layered = EnrollmentActionsScope.fits(context);

    return WalletDeletedConfirmation(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        // AnnotatedRegion replaces the whole style; the theme's has readable
        // bar icons for the current brightness (Android 15+ keeps only those).
        value:
            Theme.of(context).appBarTheme.systemOverlayStyle ??
            (YiviPalette.of(context).isDark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark),
        child: EnrollmentActionsScope(
          layered: layered,
          // The page colour under the steps: while one fades out and the
          // next in, neither covers the screen.
          child: ColoredBox(
            color: YiviPalette.of(context).background,
            child: Stack(
              children: [
                // The system back button goes back a step, as the bar's does.
                NavigatorPopHandler(
                  enabled: _hasBack(state),
                  onPopWithResult: (_) => _navigator.currentState?.maybePop(),
                  child: HeroControllerScope(
                    controller: MaterialApp.createMaterialHeroController(),
                    // A sheet goes over the bar and the buttons too.
                    child: SheetsOverEverything(
                      child: Navigator(
                        key: _navigator,
                        pages: _pages(context, state),
                        onDidRemovePage: _removed,
                      ),
                    ),
                  ),
                ),
                // Over the pages, so it stays put while they change under it.
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: EnrollmentBar(
                    step: step,
                    label: step == null ? "" : _step(context, step),
                    onBack: _hasBack(state) ? enrollment.back : null,
                  ),
                ),
                // The buttons too, on a phone held upright.
                if (layered)
                  EnrollmentActionsLayer(
                    actions: _actionsAt(context, _depth(state)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A page that fades in over the steps (setting up, a failure) instead of
/// sliding: it is not a step.
class _FadePage extends Page<void> {
  final Widget child;
  final Duration duration;

  const _FadePage({
    super.key,
    required this.child,
    this.duration = YiviMotion.standard,
  });

  @override
  Route<void> createRoute(BuildContext context) => _FadeRoute(this);
}

/// Builds from the page it has now, not the one it was made with: the done
/// page turns ready while it is on screen.
class _FadeRoute extends PageRoute<void> {
  _FadeRoute(_FadePage page) : super(settings: page);

  _FadePage get _page => settings as _FadePage;

  @override
  Duration get transitionDuration => _page.duration;

  @override
  Duration get reverseTransitionDuration => _page.duration;

  @override
  bool get opaque => true;

  @override
  bool get maintainState => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => _page.child;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => FadeTransition(opacity: animation, child: child);
}
