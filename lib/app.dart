import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n_delegate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:irmamobile/src/data/irma_client_bridge.dart';
import 'package:irmamobile/src/data/irma_client_mock.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/version_information.dart';
import 'package:irmamobile/src/prototypes/prototypes_screen.dart';
import 'package:irmamobile/src/screens/about/about_screen.dart';
import 'package:irmamobile/src/screens/change_pin/change_pin_screen.dart';
import 'package:irmamobile/src/screens/enrollment/enrollment_screen.dart';
import 'package:irmamobile/src/screens/loading/loading_screen.dart';
import 'package:irmamobile/src/screens/required_update/required_update_screen.dart';
import 'package:irmamobile/src/screens/settings/settings_screen.dart';
import 'package:irmamobile/src/screens/wallet/wallet_screen.dart';
import 'package:irmamobile/src/theme/theme.dart';

abstract class AppEvent {}

class App extends StatelessWidget {
  // Widget definition
  final String initialRoute;
  final Map<String, WidgetBuilder> routes;
  final List<BlocProvider> providers;

  App()
      : initialRoute = EnrollmentScreen.routeName,
        routes = {
          WalletScreen.routeName: (BuildContext context) => WalletScreen(),
          EnrollmentScreen.routeName: (BuildContext context) => EnrollmentScreen(),
          ChangePinScreen.routeName: (BuildContext context) => ChangePinScreen(),
          AboutScreen.routeName: (BuildContext context) => AboutScreen(),
          SettingsScreen.routeName: (BuildContext context) => SettingsScreen(),
        },
        providers = [] {
    IrmaRepository.init(IrmaClientBridge());
  }

  App.test(WidgetBuilder builder, [List<BlocProvider> providers])
      : initialRoute = '/',
        routes = {
          '/': builder,
        },
        providers = providers ?? [] {
    IrmaRepository.init(IrmaClientMock());
  }

  App.prototypes()
      : initialRoute = PrototypesScreen.routeName,
        routes = {
          PrototypesScreen.routeName: (BuildContext context) => PrototypesScreen(),
        },
        providers = [] {
    IrmaRepository.init(IrmaClientMock(
      versionUpdateAvailable: true,
    ));
  }

  App.updateRequired()
      : initialRoute = PrototypesScreen.routeName,
        routes = {
          PrototypesScreen.routeName: (BuildContext context) => PrototypesScreen(),
        },
        providers = [] {
    IrmaRepository.init(IrmaClientMock(
      versionUpdateAvailable: true,
      versionUpdateRequired: true,
    ));
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final List<LocalizationsDelegate> localizationsDelegates = [
      FlutterI18nDelegate(
        fallbackFile: 'nl',
        path: 'assets/locales',
      ),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate
    ];
    final versionInformationStream = IrmaRepository.get().getVersionInformation();
    return IrmaTheme(
      builder: (context) {
        return MultiBlocProvider(
          providers: providers,
          child: MaterialApp(
            key: const Key("app"),
            title: 'IRMA',
            theme: IrmaTheme.of(context).themeData,
            localizationsDelegates: localizationsDelegates,
            initialRoute: initialRoute,
            routes: routes,
            builder: (context, child) {
              // Use the MaterialApp builder to force an overlay when loading
              // and when update required.
              return Stack(
                children: <Widget>[
                  child,
                  StreamBuilder<VersionInformation>(
                      stream: versionInformationStream,
                      builder: (context, snapshot) {
                        switch (snapshot.connectionState) {
                          case ConnectionState.none:
                            throw Exception('Unreachable');
                            break;
                          case ConnectionState.waiting:
                            return LoadingScreen();
                            break;
                          case ConnectionState.active:
                          case ConnectionState.done:
                            break;
                        }
                        if (snapshot.data != null && snapshot.data.updateRequired()) {
                          return RequiredUpdateScreen();
                        }
                        return Container();
                      }),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
