import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n_delegate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:irmamobile/src/plugins/irma_mobile_bridge/irma_mobile_bridge_plugin.dart';
import 'package:irmamobile/src/prototypes/prototypes_screen.dart';
import 'package:irmamobile/src/screens/about/about_screen.dart';
import 'package:irmamobile/src/screens/enrollment/enrollment_screen.dart';
import 'package:irmamobile/src/screens/home/home_screen.dart';
import 'package:irmamobile/src/screens/settings/settings_screen.dart';
import 'package:irmamobile/src/theme/theme.dart';

abstract class AppEvent {}

class App extends StatelessWidget {
  // Widget definition
  final String initialRoute;

  final Map<String, WidgetBuilder> routes;

  final List<BlocProvider> providers;

  App(List<BlocProvider> providers)
      : initialRoute = EnrollmentScreen.routeName,
        routes = {
          HomeScreen.routeName: (BuildContext context) => HomeScreen(),
          EnrollmentScreen.routeName: (BuildContext context) => EnrollmentScreen(),
          AboutScreen.routeName: (BuildContext context) => AboutScreen(),
          SettingsScreen.routeName: (BuildContext context) => SettingsScreen(),
        },
        providers = providers {
    IrmaMobileBridgePlugin();
  }

  App.prototypes()
      : initialRoute = PrototypesScreen.routeName,
        routes = {
          PrototypesScreen.routeName: (BuildContext context) => PrototypesScreen(),
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
    return IrmaTheme(
      data: IrmaThemeData(),
      child: Builder(builder: (context) {
        return MultiBlocProvider(
          providers: providers,
          child: MaterialApp(
            title: 'IRMA',
            theme: IrmaTheme.of(context).themeData,
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
          ),
        );
      }),
    );
  }
}
