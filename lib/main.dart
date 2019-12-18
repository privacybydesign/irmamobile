import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n_delegate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:irmamobile/src/data/irma_client_bridge.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/data/settings/irma_settings.dart';
import 'package:irmamobile/src/models/version_information.dart';
import 'package:irmamobile/src/prototypes/prototypes_screen.dart';
import 'package:irmamobile/src/screens/about/about_screen.dart';
import 'package:irmamobile/src/screens/add_cards/card_store_screen.dart';
import 'package:irmamobile/src/screens/change_pin/change_pin_screen.dart';
import 'package:irmamobile/src/screens/enrollment/enrollment_screen.dart';
import 'package:irmamobile/src/screens/history/history_screen.dart';
import 'package:irmamobile/src/screens/loading/loading_screen.dart';
import 'package:irmamobile/src/screens/pin/pin_screen.dart';
import 'package:irmamobile/src/screens/required_update/required_update_screen.dart';
import 'package:irmamobile/src/screens/scanner/scanner_screen.dart';
import 'package:irmamobile/src/screens/settings/settings_screen.dart';
import 'package:irmamobile/src/screens/wallet/wallet_screen.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await StreamingSharedPreferences.instance;
  // Run the application
  runApp(App(preferences));
}

class App extends StatelessWidget {
  final String initialRoute;
  final Map<String, WidgetBuilder> routes;
  final IrmaSettings _settings;

  App(StreamingSharedPreferences prefs)
      : initialRoute = null,
        routes = {
          WalletScreen.routeName: (BuildContext context) => WalletScreen(),
          ScannerScreen.routeName: (BuildContext context) => ScannerScreen(),
          EnrollmentScreen.routeName: (BuildContext context) => EnrollmentScreen(),
          ChangePinScreen.routeName: (BuildContext context) => ChangePinScreen(),
          AboutScreen.routeName: (BuildContext context) => AboutScreen(),
          SettingsScreen.routeName: (BuildContext context) => SettingsScreen(),
          CardStoreScreen.routeName: (BuildContext context) => CardStoreScreen(),
          HistoryScreen.routeName: (BuildContext context) => HistoryScreen(),
        },
        _settings = IrmaSettings(prefs)
  {
    IrmaRepository(client: IrmaClientBridge());
    //IrmaSettingsRepository(settings: _settings);
  }

  App.updateRequired(StreamingSharedPreferences prefs)
      : initialRoute = PrototypesScreen.routeName,
        routes = {
          PrototypesScreen.routeName: (BuildContext context) => PrototypesScreen(),
        },
        _settings = IrmaSettings(prefs);

  static List<LocalizationsDelegate> defaultLocalizationsDelegates([Locale forcedLocale]) {
    return [
      FlutterI18nDelegate(
        fallbackFile: 'nl',
        path: 'assets/locales',
        forcedLocale: forcedLocale,
      ),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate
    ];
  }

  static List<Locale> defaultSupportedLocales() {
    return const [
      Locale('nl', 'NL'),
      Locale('en', 'US'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final versionInformationStream = IrmaRepository.get().getVersionInformation();
    return IrmaTheme(
      builder: (BuildContext context) {
        return StreamBuilder<bool>(
            stream: IrmaRepository.get().getIsEnrolled(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Container();
              }

              return MaterialApp(
                key: const Key("app"),
                title: 'IRMA',
                theme: IrmaTheme.of(context).themeData,
                localizationsDelegates: defaultLocalizationsDelegates(),
                supportedLocales: defaultSupportedLocales(),
                initialRoute: snapshot.data ? WalletScreen.routeName : EnrollmentScreen.routeName,
                routes: routes,
                builder: (context, child) {
                  // Use the MaterialApp builder to force an overlay when loading
                  // and when update required.
                  return Stack(
                    children: <Widget>[
                      child,
                      PinScreen(isEnrolled: snapshot.data),
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
              );
            });
      },
    );
  }
}
