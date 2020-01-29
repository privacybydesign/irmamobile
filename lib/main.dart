import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_i18n/flutter_i18n_delegate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:irmamobile/src/data/irma_client_bridge.dart';
import 'package:irmamobile/src/data/irma_preferences.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/version_information.dart';
import 'package:irmamobile/src/screens/about/about_screen.dart';
import 'package:irmamobile/src/screens/add_cards/card_store_screen.dart';
import 'package:irmamobile/src/screens/change_pin/change_pin_screen.dart';
import 'package:irmamobile/src/screens/disclosure/disclosure_screen.dart';
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
import 'package:irmamobile/src/util/navigator_service.dart';
import 'package:irmamobile/src/widgets/loading_indicator.dart';

void main() {
  // Run the application
  runApp(const App());
}

class App extends StatefulWidget {
  const App({Key key}) : super(key: key);

  @override
  AppState createState() => AppState();
}

class AppState extends State<App> with WidgetsBindingObserver {
  final String initialRoute;
  final Map<String, WidgetBuilder> _routes;

  // We keep track of the last two life cycle states
  // to be able to determine the flow
  List<AppLifecycleState> prevLifeCycleStates = List<AppLifecycleState>(2);

  AppState()
      : initialRoute = null,
        _routes = {
          EnrollmentScreen.routeName: (BuildContext context) => EnrollmentScreen(),
          WalletScreen.routeName: (BuildContext context) => WalletScreen(),
          ScannerScreen.routeName: (BuildContext context) => ScannerScreen(),
          ChangePinScreen.routeName: (BuildContext context) => ChangePinScreen(),
          AboutScreen.routeName: (BuildContext context) => AboutScreen(),
          SettingsScreen.routeName: (BuildContext context) => SettingsScreen(),
          CardStoreScreen.routeName: (BuildContext context) => CardStoreScreen(),
          HistoryScreen.routeName: (BuildContext context) => HistoryScreen(),
          HelpScreen.routeName: (BuildContext context) => HelpScreen(),
          DisclosureScreen.routeName: (BuildContext context) => DisclosureScreen(),
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    final startQrScanner = await IrmaPreferences.get().getStartQRScan().first;

    final navState = NavigatorService.get();

    // We check the transition goes from paused -> inactive -> resumed
    // because the transition inactive -> resumed can also happen
    // in scenarios where the app is not closed. Like an apple pay
    // authentication request or a phone call that interrupts
    // the app but doesn't pause it. In those cases we don't open
    // the QR scanner.
    if (prevLifeCycleStates[0] == AppLifecycleState.paused &&
        prevLifeCycleStates[1] == AppLifecycleState.inactive &&
        state == AppLifecycleState.resumed &&
        startQrScanner) {
      navState.pushNamed(ScannerScreen.routeName);
    }

    prevLifeCycleStates[0] = prevLifeCycleStates[1];
    prevLifeCycleStates[1] = state;
  }

  @override
  Widget build(BuildContext context) {
    IrmaRepository(client: IrmaClientBridge());

    final irmaRepo = IrmaRepository.get();
    final versionInformationStream = irmaRepo.getVersionInformation();

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
                return Container(
                  color: Colors.white,
                  child: Center(child: LoadingIndicator()),
                );
              }

              final isEnrolled = enrolledSnapshot.data;

              String initialRoute = WalletScreen.routeName;
              if (!isEnrolled) {
                initialRoute = EnrollmentScreen.routeName;
              }

              return MaterialApp(
                key: const Key("app"),
                title: 'IRMA',
                theme: IrmaTheme.of(context).themeData,
                // set showSemanticsDebugger to true to view semantics in emulator.
                showSemanticsDebugger: false,
                // TODO: Remove the forced locale when texts are properly translated to English.
                localizationsDelegates: defaultLocalizationsDelegates(const Locale('nl', 'NL')),
                supportedLocales: defaultSupportedLocales(),
                navigatorKey: NavigatorService.navigatorKey,
                initialRoute: initialRoute,
                routes: _routes,
                builder: (context, child) {
                  // Use the MaterialApp builder to force an overlay when loading
                  // and when update required.
                  return Stack(
                    children: <Widget>[
                      child,
                      if (isEnrolled) ...[
                        const PinScreen(),
                      ],
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
