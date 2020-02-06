import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/screens/enrollment/models/enrollment_bloc.dart';
import 'package:irmamobile/src/screens/enrollment/models/enrollment_event.dart';
import 'package:irmamobile/src/screens/enrollment/models/enrollment_state.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/choose_pin.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/confirm_error_dialog.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/confirm_pin.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/introduction.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/provide_email.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/submit.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/welcome.dart';
import 'package:irmamobile/src/screens/wallet/wallet_screen.dart';

class EnrollmentScreen extends StatefulWidget {
  static const routeName = "/enrollment";

  @override
  _EnrollmentScreenState createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends State<EnrollmentScreen> {
  StreamSubscription<bool> sub;

  @override
  void initState() {
    // TODO: This is probably not how we should respond to this state change
    sub = IrmaRepository.get().getIsEnrolled().listen((isEnrolled) {
      if (isEnrolled) {
        Navigator.of(context).pushReplacementNamed(WalletScreen.routeName);
        sub.cancel();
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EnrollmentBloc>(
        builder: (_) => EnrollmentBloc(),
        child: BlocBuilder<EnrollmentBloc, EnrollmentState>(builder: (context, _) {
          final bloc = BlocProvider.of<EnrollmentBloc>(context);
          return ProvidedEnrollmentScreen(bloc: bloc);
        }));
  }
}

class ProvidedEnrollmentScreen extends StatefulWidget {
  final EnrollmentBloc bloc;

  const ProvidedEnrollmentScreen({this.bloc}) : super();

  @override
  State<StatefulWidget> createState() => ProvidedEnrollmentScreenState(bloc: bloc);
}

class ProvidedEnrollmentScreenState extends State<ProvidedEnrollmentScreen> {
  FocusNode pinFocusNode;
  final EnrollmentBloc bloc;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  ProvidedEnrollmentScreenState({this.bloc}) : super();

  @override
  void initState() {
    super.initState();
    pinFocusNode = FocusNode();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Map<String, WidgetBuilder> _routeBuilders() {
    return {
      Welcome.routeName: (_) => Welcome(),
      Introduction.routeName: (_) => Introduction(),
      ChoosePin.routeName: (_) => ChoosePin(pinFocusNode: pinFocusNode, submitPin: submitPin, cancel: cancel),
      ConfirmPin.routeName: (_) => ConfirmPin(submitConfirmationPin: submitConfirmationPin, cancel: cancel),
      ProvideEmail.routeName: (_) => ProvideEmail(submitEmail: submitEmail, skipEmail: skipEmail, cancel: cancel),
      Submit.routeName: (_) => Submit(cancel: cancel, retryEnrollment: retryEnrollment),
    };
  }

  void submitPin(BuildContext context, String pin) {
    bloc.dispatch(PinSubmitted(pin: pin));
    navigatorKey.currentState.pushNamed(ConfirmPin.routeName);
  }

  void submitConfirmationPin(String pin) {
    bloc.dispatch(ConfirmationPinSubmitted(pin: pin));
  }

  void submitEmail(String email) {
    bloc.dispatch(EmailSubmitted(email: email));
  }

  void skipEmail() {
    bloc.dispatch(EmailSkipped());
  }

  void retryEnrollment() {
    bloc.dispatch(Enroll());
  }

  void cancel() {
    bloc.dispatch(EnrollmentCanceled());
  }

  @override
  Widget build(BuildContext context) {
    final routeBuilders = _routeBuilders();

    return WillPopScope(
      onWillPop: () async {
        cancel();
        return !await navigatorKey.currentState.maybePop();
      },
      child: BlocListener<EnrollmentBloc, EnrollmentState>(
        condition: (EnrollmentState previous, EnrollmentState current) {
          return (current.pinConfirmed != previous.pinConfirmed ||
                  current.showPinValidation != previous.showPinValidation) ||
              (!previous.isSubmitting && current.isSubmitting);
        },
        listener: (BuildContext context, EnrollmentState state) {
          if (state.isSubmitting == true) {
            navigatorKey.currentState.pushReplacementNamed(Submit.routeName);
          } else if (state.pinConfirmed) {
            navigatorKey.currentState.pushReplacementNamed(ProvideEmail.routeName);
          } else if (state.pinMismatch) {
            navigatorKey.currentState.popUntil((route) => route.settings.name == ChoosePin.routeName);
            // show error overlay
            showDialog(
              context: context,
              builder: (BuildContext context) => ConfirmErrorDialog(
                onClose: () async {
                  // close the overlay
                  Navigator.of(context).pop();
                  pinFocusNode.requestFocus();
                },
              ),
            );
          } else if (state.pinConfirmed == false && state.showPinValidation == true) {
            navigatorKey.currentState.popUntil((route) => route.settings.name == ChoosePin.routeName);
          }
        },
        child: Navigator(
          key: navigatorKey,
          initialRoute: Welcome.routeName,
          onGenerateRoute: (RouteSettings settings) {
            if (!routeBuilders.containsKey(settings.name)) {
              throw Exception('Invalid route: ${settings.name}');
            }
            final child = routeBuilders[settings.name];
            return MaterialPageRoute(builder: child, settings: settings);
          },
        ),
      ),
    );
  }
}
