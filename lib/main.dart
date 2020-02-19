import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_i18n/flutter_i18n_delegate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:irmamobile/routing.dart';
import 'package:irmamobile/src/data/irma_client_bridge.dart';
import 'package:irmamobile/src/data/irma_preferences.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/enrollment_status.dart';
import 'package:irmamobile/src/models/version_information.dart';
import 'package:irmamobile/src/screens/enrollment/enrollment_screen.dart';
import 'package:irmamobile/src/screens/pin/pin_screen.dart';
import 'package:irmamobile/src/screens/required_update/required_update_screen.dart';
import 'package:irmamobile/src/screens/scanner/scanner_screen.dart';
import 'package:irmamobile/src/screens/splash_screen/splash_screen.dart';
import 'package:irmamobile/src/theme/theme.dart';

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
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  // We keep track of the last two life cycle states
  // to be able to determine the flow
  List<AppLifecycleState> prevLifeCycleStates = List<AppLifecycleState>(2);

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
  bool _firstOpen = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

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
      // TODO: probably this doesn't work correctly yet with the new routing
      // stuff... I suspect it will push the ScannerScreen on top of the
      // PinScreen.
      _navigatorKey.currentState.pushNamed(ScannerScreen.routeName);

      // TODO: Use this detection also to reset the _showSplash and _removeSplash
      // variables.
    }

    prevLifeCycleStates[0] = prevLifeCycleStates[1];
    prevLifeCycleStates[1] = state;
  }

  @override
  Widget build(BuildContext context) {
    final irmaRepo = IrmaRepository.get();
    final versionInformationStream = irmaRepo.getVersionInformation();
    final enrollmentStatusStream = irmaRepo.getEnrollmentStatus();

    // Device orientation: force portrait mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return IrmaTheme(
      builder: (BuildContext context) {
        return StreamBuilder<EnrollmentStatus>(
          stream: enrollmentStatusStream,
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
                      navigatorKey: _navigatorKey,
                      onGenerateRoute: Routing.generateRoute,
                      builder: (context, child) {
                        if (_firstOpen == true) {
                          _firstOpen = false;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            // Set the initial route once, after we've learn whether we're enrolled or not
                            IrmaRepository.get()
                                .getEnrollmentStatus()
                                .firstWhere((enrollmentStatus) => enrollmentStatus != EnrollmentStatus.undetermined)
                                .then((enrollmentStatus) {
                              String targetRouteName = PinScreen.routeName;
                              if (enrollmentStatus == EnrollmentStatus.unenrolled) {
                                targetRouteName = EnrollmentScreen.routeName;
                              }
                              final pinScreenFuture = _navigatorKey.currentState.pushNamed(targetRouteName);
                              final startQrScannerFuture = IrmaPreferences.get().getStartQRScan().first;
                              pinScreenFuture.then((_) async {
                                final startQrScanner = await startQrScannerFuture;
                                if (startQrScanner == true) {
                                  _navigatorKey.currentState.pushNamed(ScannerScreen.routeName);
                                }
                              });
                            });
                          });
                        }
                        // Use the MaterialApp builder to force an overlay when loading
                        // and when update required.
                        return Stack(
                          children: <Widget>[
                            child,
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
                                child: const SplashScreen(),
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
