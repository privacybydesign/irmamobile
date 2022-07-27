import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import 'bloc/enrollment_bloc.dart';
import 'bloc/enrollment_event.dart';
import 'bloc/enrollment_state.dart';
import 'widgets/choose_pin.dart';
import 'widgets/confirm_error_dialog.dart';
import 'widgets/confirm_pin.dart';
import 'widgets/provide_email.dart';
import 'widgets/submit.dart';
import 'introduction/introduction.dart';
import '../../models/native_events.dart';
import '../../util/hero_controller.dart';
import '../../widgets/irma_repository_provider.dart';

class EnrollmentScreen extends StatelessWidget {
  static const routeName = '/enrollment';

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EnrollmentBloc>(
      create: (_) => EnrollmentBloc(FlutterI18n.currentLocale(context)!.languageCode),
      child: BlocBuilder<EnrollmentBloc, EnrollmentState>(
        builder: (context, _) {
          final bloc = BlocProvider.of<EnrollmentBloc>(context);
          return ProvidedEnrollmentScreen(bloc: bloc);
        },
      ),
    );
  }
}

class ProvidedEnrollmentScreen extends StatefulWidget {
  final EnrollmentBloc bloc;

  const ProvidedEnrollmentScreen({
    required this.bloc,
  });

  @override
  State<StatefulWidget> createState() => ProvidedEnrollmentScreenState();
}

class ProvidedEnrollmentScreenState extends State<ProvidedEnrollmentScreen> {
  final FocusNode pinFocusNode = FocusNode();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Map<String, WidgetBuilder> _routeBuilders() {
    return {
      Introduction.routeName: (_) => const Introduction(),
      ChoosePin.routeName: (_) => ChoosePin(
            pinFocusNode: pinFocusNode,
            submitPin: (context, pin) {
              widget.bloc.add(PinSubmitted(pin: pin));
              navigatorKey.currentState?.pushNamed(ConfirmPin.routeName);
            },
            cancelAndNavigate: _cancelAndNavigate,
          ),
      ConfirmPin.routeName: (_) => ConfirmPin(
            submitConfirmationPin: (pin) => widget.bloc.add(
              ConfirmationPinSubmitted(pin: pin),
            ),
            cancelAndNavigate: _cancelAndNavigate,
          ),
      ProvideEmail.routeName: (_) => ProvideEmail(
            submitEmail: (email) => widget.bloc.add(
              EmailSubmitted(email: email),
            ),
            skipEmail: () => widget.bloc.add(EmailSkipped()),
            cancelAndNavigate: _cancelAndNavigate,
          ),
      Submit.routeName: (_) => Submit(
            cancelAndNavigate: _cancelAndNavigate,
            retryEnrollment: () => widget.bloc.add(Enroll()),
          ),
    };
  }

  void _cancelAndNavigate(BuildContext context) {
    widget.bloc.add(EnrollmentCanceled());

    // Always pop at least one route (unless at the root), but return to Introduction or ChoosePin
    Navigator.maybePop(context).then(
      (_) => Navigator.of(context).popUntil(
        (route) => route.settings.name == ChoosePin.routeName || route.settings.name == Introduction.routeName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final routeBuilders = _routeBuilders();

    return WillPopScope(
      onWillPop: () async {
        final willPop = await navigatorKey.currentState?.maybePop() ?? false;
        if (!willPop) {
          IrmaRepositoryProvider.of(context).bridgedDispatch(AndroidSendToBackgroundEvent());
        }

        return false;
      },
      child: BlocListener<EnrollmentBloc, EnrollmentState>(
        listenWhen: (EnrollmentState previous, EnrollmentState current) {
          return (current.pinConfirmed != previous.pinConfirmed ||
                  current.showPinValidation != previous.showPinValidation) ||
              (!previous.isSubmitting && current.isSubmitting);
        },
        listener: (BuildContext context, EnrollmentState state) {
          if (state.isSubmitting == true) {
            navigatorKey.currentState?.pushReplacementNamed(Submit.routeName);
          } else if (state.pinConfirmed) {
            navigatorKey.currentState?.pushReplacementNamed(ProvideEmail.routeName);
          } else if (state.pinMismatch) {
            navigatorKey.currentState?.popUntil((route) => route.settings.name == ChoosePin.routeName);
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
            navigatorKey.currentState?.popUntil((route) => route.settings.name == ChoosePin.routeName);
          }
        },
        child: HeroControllerScope(
          controller: createHeroController(),
          child: Navigator(
            key: navigatorKey,
            initialRoute: Introduction.routeName,
            onGenerateRoute: (RouteSettings settings) {
              if (!routeBuilders.containsKey(settings.name)) {
                throw Exception('Invalid route: ${settings.name}');
              }
              final child = routeBuilders[settings.name]!;
              return MaterialPageRoute(builder: child, settings: settings);
            },
          ),
        ),
      ),
    );
  }
}
