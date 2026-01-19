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
    // we have to await the locked setting, because it could come after the enrollment status,
    // causing us to be automatically redirected to the pin screen when we're already unlocked...
    final locked = await repo.getLocked().first;

    if (!context.mounted) {
      return;
    }

    if (locked) {
      context.goPinScreen();
    } else {
      context.goHomeScreen();
    }
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
        systemNavigationBarIconBrightness: .dark,
      ),
      child: BlocConsumer<EnrollmentBloc, EnrollmentState>(
        listener: (BuildContext context, EnrollmentState state) {
          if (state is EnrollmentCompleted) {
            _onEnrollmentCompleted(context);
          }
        },
        builder: (context, blocState) {
          return switch (blocState) {
            EnrollmentAcceptTerms() => AcceptTermsScreen(
              isAccepted: blocState.isAccepted,
              onContinue: addOnNextPressed,
              onToggleAccepted: (isAccepted) {
                repo.preferences.markLatestTermsAsAccepted(isAccepted);
                addEvent(EnrollmentTermsUpdated(isAccepted: isAccepted));
              },
            ),
            EnrollmentChoosePin() => ChoosePinScreen(
              onPrevious: addOnPreviousPressed,
              onChoosePin: (pin) => addEvent(EnrollmentPinChosen(pin)),
              newPinNotifier: newPin,
            ),
            EnrollmentConfirmPin() => ConfirmPinScreen(
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
            ),
            EnrollmentProvideEmail() => ProvideEmailScreen(
              email: blocState.email,
              onPrevious: addOnPreviousPressed,
              onEmailSkipped: () => addEvent(EnrollmentEmailSkipped()),
              onEmailProvided: (email) {
                addEvent(EnrollmentEmailProvided(email));
              },
            ),
            EnrollmentEmailSent() => EmailSentScreen(
              email: blocState.email,
              onContinue: addOnNextPressed,
            ),
            EnrollmentFailed() => EnrollmentFailedScreen(
              onPrevious: addOnPreviousPressed,
              onRetryEnrollment: () => addEvent(EnrollmentRetried()),
            ),
            _ => Scaffold(body: Center(child: LoadingIndicator())),
          };
        },
      ),
    );
  }
}
