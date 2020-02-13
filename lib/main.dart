import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_i18n/flutter_i18n_delegate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:irmamobile/src/data/irma_client_bridge.dart';
import 'package:irmamobile/src/data/irma_preferences.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/enrollment_status.dart';
import 'package:irmamobile/src/models/version_information.dart';
import 'package:irmamobile/src/screens/about/about_screen.dart';
import 'package:irmamobile/src/screens/add_cards/card_store_screen.dart';
import 'package:irmamobile/src/screens/change_pin/change_pin_screen.dart';
import 'package:irmamobile/src/screens/debug/debug_screen.dart';
import 'package:irmamobile/src/screens/disclosure/disclosure_screen.dart';
import 'package:irmamobile/src/screens/enrollment/enrollment_screen.dart';
import 'package:irmamobile/src/screens/help/help_screen.dart';
import 'package:irmamobile/src/screens/history/history_screen.dart';
import 'package:irmamobile/src/screens/pin/pin_screen.dart';
import 'package:irmamobile/src/screens/required_update/required_update_screen.dart';
import 'package:irmamobile/src/screens/reset_pin/reset_pin_screen.dart';
import 'package:irmamobile/src/screens/scanner/scanner_screen.dart';
import 'package:irmamobile/src/screens/settings/settings_screen.dart';
import 'package:irmamobile/src/screens/splash_screen/splash_screen.dart';
import 'package:irmamobile/src/screens/wallet/wallet_screen.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/util/navigator_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  IrmaRepository(client: IrmaClientBridge());

  runApp(const App());
}

class App extends StatefulWidget {
  const App({Key key}) : super(key: key);

  @override
  AppState createState() => AppState();
}

class AppState extends State<App> with WidgetsBindingObserver {
  String initialRoute;

  // We keep track of the last two life cycle states
  // to be able to determine the flow
  List<AppLifecycleState> prevLifeCycleStates = List<AppLifecycleState>(2);

  AppState();

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

  bool _showSplash = true;
  bool _removeSplash = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Set the initial route once, after we've learn whether we're enrolled or not
    IrmaRepository.get()
        .getEnrollmentStatus()
        .firstWhere((enrollmentStatus) => enrollmentStatus != EnrollmentStatus.undetermined)
        .then((enrollmentStatus) {
      setState(() {
        initialRoute =
            enrollmentStatus == EnrollmentStatus.enrolled ? WalletScreen.routeName : EnrollmentScreen.routeName;
      });
    });

    // TODO: the delay before splash is hidden is quite long. This is because we
    // currently have a long startup time (although that may be because we run
    // in debug). This value should eventually be lowered to 500.
    Future.delayed(const Duration(milliseconds: 2500)).then((_) {
      setState(() {
        _showSplash = false;
      });
    });
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

<<<<<<< HEAD
  Widget _determineRoute(String routeName, Object arguments) {
    switch (routeName) {
      case "/":
        return Container();
      case DisclosureScreen.routeName:
        return DisclosureScreen(arguments: arguments as DisclosureScreenArguments);
      case EnrollmentScreen.routeName:
        return EnrollmentScreen();
      case WalletScreen.routeName:
        return WalletScreen();
      case ScannerScreen.routeName:
        return ScannerScreen();
      case ChangePinScreen.routeName:
        return ChangePinScreen();
      case AboutScreen.routeName:
        return AboutScreen();
      case SettingsScreen.routeName:
        return SettingsScreen();
      case CardStoreScreen.routeName:
        return CardStoreScreen();
      case HistoryScreen.routeName:
        return HistoryScreen();
      case HelpScreen.routeName:
        return HelpScreen();
      case ResetPinScreen.routeName:
        return ResetPinScreen();
      case DebugScreen.routeName:
        return DebugScreen();
    }

    throw "Unrecognized route was pushed";
  }

=======
>>>>>>> fix(wallet): slide in drawer not working on ios
  @override
  Widget build(BuildContext context) {
    final irmaRepo = IrmaRepository.get();
    final versionInformationStream = irmaRepo.getVersionInformation();

    // Device orientation: force portrait mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return IrmaTheme(
      builder: (BuildContext context) {
        return StreamBuilder<EnrollmentStatus>(
          stream: irmaRepo.getEnrollmentStatus(),
          builder: (context, enrollmentStatusSnapshop) {
            final enrollmentStatus = enrollmentStatusSnapshop.data;

            return StreamBuilder<VersionInformation>(
              stream: versionInformationStream,
              builder: (context, versionInformationSnapshot) {
                // NOTE: versionInformation can be null because there is no guarantee that
                // versionInformationSnapshot.data is not null.
                final versionInformation = versionInformationSnapshot.data;

                return Stack(
                  textDirection: TextDirection.ltr,
                  children: <Widget>[
                    MaterialApp(
                      key: const Key("app"),
                      title: 'IRMA',
                      theme: IrmaTheme.of(context).themeData,
                      // set showSemanticsDebugger to true to view semantics in emulator.
                      showSemanticsDebugger: false,
                      // TODO: Remove the forced locale when texts are properly translated to English.
                      localizationsDelegates: defaultLocalizationsDelegates(),
                      supportedLocales: defaultSupportedLocales(),
                      navigatorKey: NavigatorService.navigatorKey,
                      initialRoute: initialRoute,
                      routes: <String, WidgetBuilder>{
                        WalletScreen.routeName: (context) => WalletScreen(),
                        EnrollmentScreen.routeName: (context) => EnrollmentScreen(),
                        ScannerScreen.routeName: (context) => ScannerScreen(),
                        ChangePinScreen.routeName: (context) => ChangePinScreen(),
                        AboutScreen.routeName: (context) => AboutScreen(),
                        SettingsScreen.routeName: (context) => SettingsScreen(),
                        CardStoreScreen.routeName: (context) => CardStoreScreen(),
                        HistoryScreen.routeName: (context) => HistoryScreen(),
                        HelpScreen.routeName: (context) => HelpScreen(),
                        ResetPinScreen.routeName: (context) => ResetPinScreen(),
                      },
                      onGenerateRoute: (settings) {
                        if (settings.name == DisclosureScreen.routeName) {
                          return MaterialPageRoute(
                              builder: (context) {
                                return DisclosureScreen(arguments: settings.arguments as DisclosureScreenArguments);
                              },
                              settings: settings);
                        }
                        return null;
                      },
                      builder: (context, child) {
                        // Use the MaterialApp builder to force an overlay when loading
                        // and when update required.
                        return Stack(
                          children: <Widget>[
                            child,
                            if (enrollmentStatus == EnrollmentStatus.enrolled) ...[
                              const PinScreen(),
                            ],
                            if (versionInformation != null && versionInformation.updateRequired()) ...[
                              RequiredUpdateScreen(),
                            ],
                            if (_removeSplash == false) ...[
                              AnimatedOpacity(
                                opacity: versionInformation == null ||
                                        enrollmentStatus == EnrollmentStatus.undetermined ||
                                        _showSplash
                                    ? 1.0
                                    : 0.0,
                                duration: const Duration(milliseconds: 500),
                                onEnd: () {
                                  setState(() {
                                    _removeSplash = true;
                                  });
                                },
                                child: SplashScreen(),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
