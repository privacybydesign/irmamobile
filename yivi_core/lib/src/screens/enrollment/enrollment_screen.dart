import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";

import "../../providers/preferences_provider.dart";
import "../../theme/yivi_palette.dart";
import "../../theme/yivi_space.dart";
import "../../util/i18n.dart";
import "../../util/navigation.dart";
import "../../widgets/translated_text.dart";
import "../../widgets/yivi_spinner.dart";
import "biometric/enrollment_biometric_screen.dart";
import "choose_pin/choose_pin_screen.dart";
import "confirm_pin/confirm_pin_screen.dart";
import "confirm_pin/widgets/pin_confirmation_failed_dialog.dart";
import "email/enrollment_email_screen.dart";
import "enrollment_failed_screen.dart";
import "enrollment_provider.dart";
import "enrollment_state.dart";
import "welcome/welcome_screen.dart";

class EnrollmentScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends ConsumerState<EnrollmentScreen> {
  /// The PIN chosen in the first step, for the confirm step to compare
  /// with. Kept here, not in build: anything that rebuilds the screen
  /// between the two steps (a theme change) would otherwise forget it.
  final _newPin = ValueNotifier("");

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

  String _step(
    BuildContext context,
    EnrollmentStepNumber step, {
    String key = "enrollment.step",
  }) =>
      context.tr(key, {"current": "${step.number}", "total": "${step.total}"});

  @override
  Widget build(BuildContext context) {
    final enrollment = ref.read(enrollmentProvider.notifier);
    ref.listen(enrollmentProvider, (_, state) {
      if (state is EnrollmentCompleted) _onEnrollmentCompleted(context);
    });
    final state = ref.watch(enrollmentProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // AnnotatedRegion replaces the whole style; the theme's has readable
      // bar icons for the current brightness (Android 15+ keeps only those).
      value:
          Theme.of(context).appBarTheme.systemOverlayStyle ??
          (YiviPalette.of(context).isDark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark),
      child: switch (state) {
        EnrollmentWelcome(:final isAccepted) => WelcomeScreen(
          isAccepted: isAccepted,
          onContinue: () => enrollment.next(language: context.lang),
          onToggleAccepted: (isAccepted) {
            ref.read(preferencesProvider).acceptedLatestTerms.set(isAccepted);
            enrollment.setTermsAccepted(isAccepted);
          },
        ),
        EnrollmentChoosePin(:final step) => ChoosePinScreen(
          stepLabel: step == null ? null : _step(context, step),
          onPrevious: enrollment.back,
          onChoosePin: enrollment.pinChosen,
          newPinNotifier: _newPin,
        ),
        EnrollmentConfirmPin(:final step) => ConfirmPinScreen(
          stepLabel: step == null ? null : _step(context, step),
          newPinNotifier: _newPin,
          onPrevious: enrollment.back,
          submitConfirmationPin: enrollment.pinConfirmed,
          onPinMismatch: () {
            showPinConfirmationFailedDialog(
              context,
              onPressed: (context) {
                enrollment.pinMismatch();
                context.pop();
              },
            );
          },
        ),
        EnrollmentBiometric(:final step) => EnrollmentBiometricScreen(
          stepLabel: _step(context, step),
          onDone: enrollment.biometricDone,
        ),
        EnrollmentEmail(:final step) => EnrollmentEmailScreen(
          stepLabel: _step(context, step, key: "enrollment.step_optional"),
          account: () => enrollment.account,
          link: enrollment.emailLink!,
          onDone: enrollment.emailDone,
          onAccountFailed: enrollment.accountFailed,
        ),
        EnrollmentFailed() => EnrollmentFailedScreen(
          onPrevious: enrollment.back,
          onRetryEnrollment: enrollment.retry,
        ),
        // Waiting for the account after the last step: the logo, a
        // spinner and "Setting up your app".
        Enrolling() ||
        EnrollmentCompleted() => _SettingUp(showText: state is Enrolling),
      },
    );
  }
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
              YiviSpinner(),
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
