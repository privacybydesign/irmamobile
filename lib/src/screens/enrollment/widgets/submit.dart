import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/screens/enrollment/email_sent_screen.dart';
import 'package:irmamobile/src/screens/enrollment/models/enrollment_bloc.dart';
import 'package:irmamobile/src/screens/enrollment/models/enrollment_state.dart';
import 'package:irmamobile/src/screens/error/session_error_screen.dart';
import 'package:irmamobile/src/screens/wallet/wallet_screen.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/progress.dart';

class Submit extends StatefulWidget {
  static const String routeName = 'submit';

  final void Function(BuildContext) cancelAndNavigate;
  final void Function() retryEnrollment;

  const Submit({
    @required this.cancelAndNavigate,
    @required this.retryEnrollment,
  });

  @override
  _SubmitState createState() => _SubmitState();
}

class _SubmitState extends State<Submit> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: IrmaAppBar(
        title: Text(
          FlutterI18n.translate(context, 'enrollment.submit.title'),
        ),
        leadingAction: () => widget.cancelAndNavigate(context),
        leadingTooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
      ),
      body: BlocListener<EnrollmentBloc, EnrollmentState>(
          condition: (previous, current) {
            return previous.isSubmitting && !current.isSubmitting;
          },
          listener: (context, state) {
            if (state.submittingFailed) {
              Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (context) => SessionErrorScreen(
                  error: state.error,
                  onTapClose: () => Navigator.of(context).pop(),
                  onTapRetry: () {
                    Navigator.of(context).pop();
                    widget.retryEnrollment();
                  },
                ),
              ));
            } else {
              // Enrollment succeeded
              Navigator.of(context).pop();
              if (state.showEmailValidation) {
                Navigator.of(context)
                    .pushReplacement(MaterialPageRoute(builder: (context) => EmailSentScreen(email: state.email)));
              } else {
                Navigator.of(context, rootNavigator: true).pushReplacementNamed(WalletScreen.routeName);
              }
            }
          },
          child: IrmaProgress(
            FlutterI18n.translate(context, "enrollment.submit.progress_enrollment"),
          )),
    );
  }
}
