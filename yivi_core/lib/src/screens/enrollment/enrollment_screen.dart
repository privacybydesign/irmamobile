import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";

import "../../data/irma_repository.dart";
import "../../providers/email_linking_provider.dart";
import "../../providers/irma_repository_provider.dart";
import "../../theme/yivi_palette.dart";
import "../../util/navigation.dart";
import "../../widgets/loading_indicator.dart";
import "../../widgets/translated_text.dart";
import "../pin/providers/biometric_provider.dart";
import "biometric/enrollment_biometric_screen.dart";
import "bloc/enrollment_bloc.dart";
import "choose_pin/choose_pin_screen.dart";
import "confirm_pin/confirm_pin_screen.dart";
import "confirm_pin/widgets/pin_confirmation_failed_dialog.dart";
import "email/enrollment_email_screen.dart";
import "enrollment_failed_screen.dart";
import "welcome/welcome_screen.dart";

class EnrollmentScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final repo = IrmaRepositoryProvider.of(context);
    final container = ProviderScope.containerOf(context, listen: false);
    return BlocProvider(
      create: (_) => EnrollmentBloc(
        language: FlutterI18n.currentLocale(context)!.languageCode,
        repo: repo,
        // Once, only if a biometric is enrolled and the user hasn't chosen.
        biometricOffered: () async {
          final available = await container.read(
            biometricAvailableProvider.future,
          );
          final enabled = await repo.preferences.getBiometricEnabled().first;
          final dismissed = await repo.preferences
              .getBiometricPromptDismissed()
              .first;
          return available && !enabled && !dismissed;
        },
        emailOffered: () => container.read(emailLinkingOfferedProvider),
      ),
      child: _ProvidedEnrollmentScreen(repo: repo),
    );
  }
}

class _ProvidedEnrollmentScreen extends StatelessWidget {
  final IrmaRepository repo;

  const _ProvidedEnrollmentScreen({required this.repo});

  Future<void> _onEnrollmentCompleted(BuildContext context) async {
    // The empty Data tab points out the Scan button on the first visit.
    await repo.preferences.markScanTipPending();
    // LockGate handles displaying the PIN overlay if the app is still
    // locked after enrollment.
    if (context.mounted) context.goHomeScreen();
  }

  String _step(BuildContext context, EnrollmentStepNumber step) =>
      FlutterI18n.translate(
        context,
        "enrollment.step",
        translationParams: {
          "current": "${step.number}",
          "total": "${step.total}",
        },
      );

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<EnrollmentBloc>();
    void addEvent(EnrollmentBlocEvent event) => bloc.add(event);
    void addOnPreviousPressed() => bloc.add(EnrollmentPreviousPressed());
    void addOnNextPressed() => bloc.add(EnrollmentNextPressed());
    final newPin = ValueNotifier("");

    // The default for this value is intentionally
    // different for the fresh install and upgrade flows.
    repo.preferences.setLongPin(false);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // AnnotatedRegion replaces the whole style; the theme's has readable
      // bar icons for the current brightness (Android 15+ keeps only those).
      value:
          Theme.of(context).appBarTheme.systemOverlayStyle ??
          (Theme.of(context).brightness == Brightness.dark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark),
      child: BlocConsumer<EnrollmentBloc, EnrollmentState>(
        listener: (BuildContext context, EnrollmentState state) {
          if (state is EnrollmentCompleted) {
            _onEnrollmentCompleted(context);
          }
        },
        builder: (context, state) {
          if (state is EnrollmentWelcome) {
            return WelcomeScreen(
              isAccepted: state.isAccepted,
              onContinue: addOnNextPressed,
              onToggleAccepted: (isAccepted) {
                repo.preferences.markLatestTermsAsAccepted(isAccepted);
                addEvent(EnrollmentTermsUpdated(isAccepted: isAccepted));
              },
            );
          }
          if (state is EnrollmentChoosePin) {
            return ChoosePinScreen(
              stepLabel: state.step == null
                  ? null
                  : _step(context, state.step!),
              onPrevious: addOnPreviousPressed,
              onChoosePin: (pin) => addEvent(EnrollmentPinChosen(pin)),
              newPinNotifier: newPin,
            );
          }
          if (state is EnrollmentConfirmPin) {
            return ConfirmPinScreen(
              stepLabel: state.step == null
                  ? null
                  : _step(context, state.step!),
              newPinNotifier: newPin,
              onPrevious: addOnPreviousPressed,
              submitConfirmationPin: (pin) =>
                  addEvent(EnrollmentPinConfirmed(pin)),
              onPinMismatch: () {
                showDialog(
                  barrierDismissible: false,
                  context: context,
                  builder: (context) => PinConfirmationFailedDialog(
                    onPressed: () {
                      addEvent(EnrollmentPinMismatch());
                      context.pop();
                    },
                  ),
                );
              },
            );
          }
          if (state is EnrollmentBiometric) {
            return EnrollmentBiometricScreen(
              stepLabel: _step(context, state.step),
              onDone: () => addEvent(EnrollmentBiometricDone()),
            );
          }
          if (state is EnrollmentEmail) {
            return EnrollmentEmailScreen(
              stepLabel: FlutterI18n.translate(
                context,
                "enrollment.step_optional",
                translationParams: {
                  "current": "${state.step.number}",
                  "total": "${state.step.total}",
                },
              ),
              account: () => bloc.account,
              pin: bloc.pin!,
              onDone: () => addEvent(EnrollmentEmailDone()),
              onAccountFailed: (error) =>
                  addEvent(EnrollmentAccountFailed(error)),
            );
          }
          if (state is EnrollmentFailed) {
            return EnrollmentFailedScreen(
              onPrevious: addOnPreviousPressed,
              onRetryEnrollment: () => addEvent(EnrollmentRetried()),
            );
          }
          // Waiting for the account after the last step: the logo, a
          // spinner and "Setting up your app".
          return _SettingUp(showText: state is Enrolling);
        },
      ),
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
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: SvgPicture.asset(
                  YiviPalette.of(context).logoAsset,
                  height: 52,
                ),
              ),
              const SizedBox(height: 40),
              LoadingIndicator(),
              if (showText) ...[
                const SizedBox(height: 24),
                TranslatedText(
                  "enrollment.setting_up",
                  isHeader: true,
                  textAlign: TextAlign.center,
                  style: palette.display(20),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
