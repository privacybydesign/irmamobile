import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n_delegate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/enrollment/enrollment.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  final String initialRoute;

  final Map<String, WidgetBuilder> routes;

  final List<BlocProvider> providers;

  App()
      : initialRoute = '/enrollment',
        routes = {
          '/': (BuildContext context) => Text('Home'),
          '/enrollment': (BuildContext context) => Enrollment(),
        },
        providers = [];

  App.test(WidgetBuilder builder, [List<BlocProvider> providers])
      : initialRoute = '/',
        routes = {
          '/': builder,
        },
        providers = providers == null ? [] : providers;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
        providers: providers,
        child: MaterialApp(
          title: 'IRMA',
          localizationsDelegates: [
            FlutterI18nDelegate(
              fallbackFile: 'nl',
              path: 'assets/locales',
            ),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate
          ],
          initialRoute: initialRoute,
          routes: routes,
        ));
  }
}
