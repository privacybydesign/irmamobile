import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:irmamobile/src/screens/add_card_email/model/attribute_requester.dart';
import 'package:irmamobile/src/screens/add_card_email/model/request_email_bloc.dart';
import 'package:irmamobile/src/screens/add_card_email/model/request_email_state.dart';
import 'package:irmamobile/src/screens/add_card_email/widgets/email_attribute_confirmation.dart';
import 'package:irmamobile/src/screens/add_card_email/widgets/request_email_atribute.dart';

class AddEmailCardScreen extends StatefulWidget {
  static final routeName = "store/email";
  final String requestEmailUrl;

  AddEmailCardScreen(this.requestEmailUrl);

  @override
  State<StatefulWidget> createState() => AddEmailCardState();
}

class AddEmailCardState extends State<AddEmailCardScreen> {
  GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static final _routeBuilders = {
    RequestEmailAttribute.routeName: (_) => RequestEmailAttribute(
          "E-mailadres",
          "IRMA Privacy by design",
          "assets/non-free/irmalogo.png",
        ),
    EmailAttributeConfirmation.routeName: (_) => EmailAttributeConfirmation(),
  };

  @override
  Widget build(BuildContext context) {
    final buildListener = (BuildContext context, Widget child) {
      return BlocListener<RequestEmailBloc, RequestEmailState>(
        condition: (previousState, newState) {
          return !previousState.emailAttributeRequested && newState.emailAttributeRequested;
        },
        listener: (BuildContext context, RequestEmailState state) {
          if (state.emailAttributeRequested) {
            Navigator.of(context).pushReplacementNamed(EmailAttributeConfirmation.routeName);
          }
        },
        child: child,
      );
    };

    return BlocProvider<RequestEmailBloc>(
      builder: (context) => RequestEmailBloc(
        "", // TODO: use registration e-mail if present.
        EmailAttributeRequesterMock(
          true,
        ),
      ),
      child: Navigator(
        key: navigatorKey,
        initialRoute: RequestEmailAttribute.routeName,
        onGenerateRoute: (RouteSettings settings) {
          return MaterialPageRoute(
            builder: (BuildContext c) => buildListener(
              c,
              _routeBuilders[settings.name](c),
            ),
            settings: settings,
          );
        },
      ),
    );
  }
}
