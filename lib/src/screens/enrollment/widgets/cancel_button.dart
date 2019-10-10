import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:irmamobile/src/screens/enrollment/models/enrollment_bloc.dart';
import 'package:irmamobile/src/screens/enrollment/models/enrollment_event.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/welcome.dart';

class CancelButton extends StatelessWidget {
  final String routeName;

  CancelButton({
    @required this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    final EnrollmentBloc enrollmentBloc = BlocProvider.of<EnrollmentBloc>(context);

    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        enrollmentBloc.dispatch(EnrollmentCanceled());
        Navigator.of(context)
            .popUntil((route) => route.settings.name == routeName || route.settings.name == Welcome.routeName);
      },
      tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
    );
  }
}
