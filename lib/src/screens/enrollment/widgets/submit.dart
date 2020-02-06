import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/screens/enrollment/models/enrollment_bloc.dart';
import 'package:irmamobile/src/screens/enrollment/models/enrollment_state.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/choose_pin.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/welcome.dart';
import 'package:irmamobile/src/screens/error/no_internet.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/progress.dart';

class Submit extends StatefulWidget {
  static const String routeName = 'submit';

  final void Function() cancel;
  final void Function() retryEnrollment;

  const Submit({
    @required this.cancel,
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
        leadingCancel: widget.cancel,
        leadingAction: () {
          Navigator.of(context).popUntil(
              (route) => route.settings.name == ChoosePin.routeName || route.settings.name == Welcome.routeName);
        },
        leadingTooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
      ),
      body: BlocBuilder<EnrollmentBloc, EnrollmentState>(
        builder: (context, state) {
          if (state.enrollementFailed == true) {
            return NoInternet(
              () {
                widget.retryEnrollment();
              },
            );
          }

          return IrmaProgress(
            FlutterI18n.translate(context, "enrollment.submit.progress_enrollment"),
          );
        },
      ),
    );
  }
}
