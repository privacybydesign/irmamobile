import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:go_router/go_router.dart";

import "../../data/irma_repository.dart";
import "../../providers/irma_repository_provider.dart";
import "../../util/navigation.dart";
import "../../widgets/loading_indicator.dart";
import "accept_terms/accept_terms_screen.dart";
import "bloc/enrollment_bloc.dart";
import "choose_pin/choose_pin_screen.dart";
import "confirm_pin/confirm_pin_screen.dart";
import "confirm_pin/widgets/pin_confirmation_failed_dialog.dart";
import "enrollment_failed_screen.dart";
import "introduction/introduction_screen.dart";
import "provide_email/email_sent_screen.dart";
import "provide_email/provide_email_screen.dart";

class EnrollmentScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final repo = IrmaRepositoryProvider.of(context);
    return BlocProvider(
      create: (_) => EnrollmentBloc(
        language: FlutterI18n.currentLocale(context)!.languageCode,
        repo: repo,
      ),
      child: _ProvidedEnrollmentScreen(repo: repo),
    );
  }
}

class _ProvidedEnrollmentScreen extends StatelessWidget {
  final IrmaRepository repo;

  const _ProvidedEnrollmentScreen({required this.repo});

  Future<void> _onEnrollmentCompleted(BuildContext context) async {
    if (!context.mounted) return;
    // LockGate handles displaying the PIN overlay if the app is still
    // locked after enrollment.
    context.goHomeScreen();
  }

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
      value: const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: BlocConsumer<EnrollmentBloc, EnrollmentState>(
        listener: (BuildContext context, EnrollmentState state) {
          if (state is EnrollmentCompleted) {
            _onEnrollmentCompleted(context);
          }
        },
        builder: (context, blocState) {
          var state = blocState;
          if (state is EnrollmentIntroduction) {
            return IntroductionScreen(
              currentStepIndex: state.currentStepIndex,
              onContinue: addOnNextPressed,
              onPrevious: addOnPreviousPressed,
            );
          }
          if (state is EnrollmentChoosePin) {
            return ChoosePinScreen(
              onPrevious: addOnPreviousPressed,
              onChoosePin: (pin) => addEvent(EnrollmentPinChosen(pin)),
              newPinNotifier: newPin,
            );
          }
          if (state is EnrollmentConfirmPin) {
            return ConfirmPinScreen(
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
          if (state is EnrollmentProvideEmail) {
            return ProvideEmailScreen(
              email: state.email,
              onPrevious: addOnPreviousPressed,
              onEmailSkipped: () => addEvent(EnrollmentEmailSkipped()),
              onEmailProvided: (email) =>
                  addEvent(EnrollmentEmailProvided(email)),
            );
          }
          if (state is EnrollmentEmailSent) {
            return EmailSentScreen(
              email: state.email,
              onContinue: addOnNextPressed,
            );
          }
          if (state is EnrollmentAcceptTerms) {
            return AcceptTermsScreen(
              isAccepted: state.isAccepted,
              onPrevious: addOnPreviousPressed,
              onContinue: addOnNextPressed,
              onToggleAccepted: (isAccepted) {
                repo.preferences.markLatestTermsAsAccepted(isAccepted);
                addEvent(EnrollmentTermsUpdated(isAccepted: isAccepted));
              },
            );
          }
          if (state is EnrollmentFailed) {
            return EnrollmentFailedScreen(
              onPrevious: addOnPreviousPressed,
              onRetryEnrollment: () => addEvent(EnrollmentRetried()),
            );
          }
          // If state is loading/initial/submitting show centered loading indicator
          return Scaffold(body: Center(child: LoadingIndicator()));
        },
      ),
    );
  }
}
