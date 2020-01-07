import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_i18n/flutter_i18n_delegate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:irmamobile/src/data/irma_client_bridge.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/version_information.dart';
import 'package:irmamobile/src/prototypes/prototypes_screen.dart';
import 'package:irmamobile/src/screens/about/about_screen.dart';
import 'package:irmamobile/src/screens/add_cards/card_store_screen.dart';
import 'package:irmamobile/src/screens/change_pin/change_pin_screen.dart';
import 'package:irmamobile/src/screens/enrollment/enrollment_screen.dart';
import 'package:irmamobile/src/screens/help/help_screen.dart';
import 'package:irmamobile/src/screens/history/history_screen.dart';
import 'package:irmamobile/src/screens/loading/loading_screen.dart';
import 'package:irmamobile/src/screens/pin/pin_screen.dart';
import 'package:irmamobile/src/screens/required_update/required_update_screen.dart';
import 'package:irmamobile/src/screens/scanner/scanner_screen.dart';
import 'package:irmamobile/src/screens/settings/settings_screen.dart';
import 'package:irmamobile/src/screens/wallet/wallet_screen.dart';
import 'package:irmamobile/src/theme/theme.dart';

void main() {
  // Run the application
  runApp(App());
}

class App extends StatelessWidget {
  final String initialRoute;
  final Map<String, WidgetBuilder> routes;

  App()
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
          HelpScreen.routeName: (BuildContext context) => HelpScreen(),
        };

  App.updateRequired()
      : initialRoute = PrototypesScreen.routeName,
        routes = {
          PrototypesScreen.routeName: (BuildContext context) => PrototypesScreen(),
        };

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
    IrmaRepository(client: IrmaClientBridge());

    final irmaRepo = IrmaRepository.get();
    final versionInformationStream = irmaRepo.getVersionInformation();
    final startQrStream = irmaRepo.getPreferences().map((p) => p.qrScannerOnStartup);

    // Device orientation: force portrait mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return IrmaTheme(
      builder: (BuildContext context) {
        return StreamBuilder<bool>(
            stream: irmaRepo.getIsEnrolled(),
            builder: (context, enrolledSnapshot) {
              if (!enrolledSnapshot.hasData) {
                return Container();
              }
              return StreamBuilder<bool>(
                  stream: startQrStream,
                  builder: (context, startQrSnapshot) {
                    if (!startQrSnapshot.hasData) {
                      return Container();
                    }

                    var initialRoute = WalletScreen.routeName;
                    if (enrolledSnapshot.data == false) {
                      initialRoute = EnrollmentScreen.routeName;
                    } else if (startQrSnapshot.data == true) {
                      initialRoute = ScannerScreen.routeName;
                    }

                    return MaterialApp(
                      key: const Key("app"),
                      title: 'IRMA',
                      theme: IrmaTheme.of(context).themeData,
                      localizationsDelegates: defaultLocalizationsDelegates(),
                      supportedLocales: defaultSupportedLocales(),
                      initialRoute: initialRoute,
                      routes: routes,
                      builder: (context, child) {
                        // Use the MaterialApp builder to force an overlay when loading
                        // and when update required.
                        return Stack(
                          children: <Widget>[
                            child,
                            PinScreen(isEnrolled: enrolledSnapshot.data),
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
            });
      },
    );
  }
}
