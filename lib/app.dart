import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_i18n/flutter_i18n_delegate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:irmamobile/routing.dart';
import 'package:irmamobile/src/data/irma_preferences.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/applifecycle_changed_event.dart';
import 'package:irmamobile/src/models/clear_all_data_event.dart';
import 'package:irmamobile/src/models/enrollment_status.dart';
import 'package:irmamobile/src/models/native_events.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:irmamobile/src/models/update_schemes_event.dart';
import 'package:irmamobile/src/models/version_information.dart';
import 'package:irmamobile/src/screens/enrollment/enrollment_screen.dart';
import 'package:irmamobile/src/screens/pin/pin_screen.dart';
import 'package:irmamobile/src/screens/required_update/required_update_screen.dart';
import 'package:irmamobile/src/screens/reset_pin/reset_pin_screen.dart';
import 'package:irmamobile/src/screens/rooted_warning/repository.dart';
import 'package:irmamobile/src/screens/rooted_warning/rooted_warning_screen.dart';
import 'package:irmamobile/src/screens/scanner/scanner_screen.dart';
import 'package:irmamobile/src/screens/splash_screen/splash_screen.dart';
import 'package:irmamobile/src/screens/wallet/wallet_screen.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/util/combine.dart';
import 'package:irmamobile/src/util/hero_controller.dart';

const schemeUpdateIntervalHours = 3;

class App extends StatefulWidget {
  const App({Key key}) : super(key: key);

  @override
  AppState createState() => AppState();
}

class AppState extends State<App> with WidgetsBindingObserver, NavigatorObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final _detectRootedDeviceRepo = DetectRootedDeviceIrmaPrefsRepository();
  StreamSubscription<SessionPointer> _sessionPointerSubscription;
  bool _qrScannerActive = false;
  DateTime lastSchemeUpdate;

  // We keep track of the last two life cycle states
  // to be able to determine the flow
  List<AppLifecycleState> prevLifeCycleStates = List<AppLifecycleState>(2);

  AppState();

  static List<LocalizationsDelegate> defaultLocalizationsDelegates([Locale forcedLocale]) {
    return [
      FlutterI18nDelegate(
        translationLoader: FileTranslationLoader(
          fallbackFile: 'en',
          basePath: 'assets/locales',
          forcedLocale: forcedLocale,
        ),
      ),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate
    ];
  }

  static List<Locale> defaultSupportedLocales() {
    return const [
      Locale('en', 'US'),
      Locale('nl', 'NL'),
    ];
  }

  bool _showSplash = true;
  bool _removeSplash = false;

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

    _listenForDataClear();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    final repo = IrmaRepository.get();
    repo.dispatch(AppLifecycleChangedEvent(state));

    if (state == AppLifecycleState.resumed &&
        (lastSchemeUpdate == null || DateTime.now().difference(lastSchemeUpdate).inHours > schemeUpdateIntervalHours)) {
      lastSchemeUpdate = DateTime.now();
      repo.bridgedDispatch(UpdateSchemesEvent());
    }

    // Forget about previous issuance session via in app browser once app
    // is dismissed
    if (state == AppLifecycleState.paused) {
      repo.processInactivation();
    }

    // We check the transition goes from paused -> inactive -> resumed
    // because the transition inactive -> resumed can also happen
    // in scenarios where the app is not closed. Like an apple pay
    // authentication request or a phone call that interrupts
    // the app but doesn't pause it. In those cases we don't open
    // the QR scanner.
    if (prevLifeCycleStates[0] == AppLifecycleState.paused &&
        prevLifeCycleStates[1] == AppLifecycleState.inactive &&
        state == AppLifecycleState.resumed) {
      // First check whether we should redo pin verification
      final lastActive = await repo.getLastActiveTime().first;
      final status = await repo.getEnrollmentStatus().firstWhere((status) => status != EnrollmentStatus.undetermined);
      final locked = await repo.getLocked().first;
      if (status == EnrollmentStatus.enrolled) {
        if (!locked && lastActive.isBefore(DateTime.now().subtract(const Duration(minutes: 5)))) {
          repo.lock();
        } else {
          _maybeOpenQrScanner();
        }
      }
    }

    // TODO: Use this detection also to reset the _showSplash and _removeSplash
    // variables.
    prevLifeCycleStates[0] = prevLifeCycleStates[1];
    prevLifeCycleStates[1] = state;
  }

  @override
  void didPush(Route route, Route previousRoute) {
    _onScreenPushed(route);
  }

  @override
  void didReplace({Route newRoute, Route oldRoute}) {
    _onScreenPopped(oldRoute);
    _onScreenPushed(newRoute);
  }

  @override
  void didPop(Route route, Route previousRoute) {
    _onScreenPopped(route);
  }

  @override
  void didRemove(Route route, Route previousRoute) {
    _onScreenPopped(route);
  }

  void _onScreenPushed(Route route) {
    switch (route.settings.name) {
      case WalletScreen.routeName:
        // We have to make sure that sessions can be started once the
        //  wallet screen has been pushed to the navigator. Otherwise
        //  the session screens have no wallet screen to pop back to.
        //  The wallet screen is only pushed when the user is fully enrolled.
        _listenToPendingSessionPointer();
        _maybeOpenQrScanner();
        break;

      case ScannerScreen.routeName:
        // Check whether the qr code scanner is active to prevent the scanner
        //  from being re-launched over a previous instance on startup.
        _qrScannerActive = true;
        break;

      default:
    }
  }

  void _onScreenPopped(Route route) {
    switch (route.settings.name) {
      case WalletScreen.routeName:
        _sessionPointerSubscription.cancel();
        break;
      case ScannerScreen.routeName:
        _qrScannerActive = false;
        break;
      default:
    }
  }

  void _listenToPendingSessionPointer() {
    final repo = IrmaRepository.get();

    // Listen for incoming SessionPointers as long as the wallet screen is there.
    //  We can always act on these, because if the app is locked,
    //  their screens will simply be covered.
    _sessionPointerSubscription = repo.getPendingSessionPointer().listen((sessionPointer) {
      if (sessionPointer == null) {
        return;
      }

      _startSession(sessionPointer);
    });
  }

  void _listenForDataClear() {
    // Clearing all data can be done both from the pin entry screen, or from
    // the settings screen. As these are on different navigation stacks entirely,
    // we cannot there manipulate the desired navigation stack for the enrollment
    // screen. Hence, we do that here, pushing the enrollment screen on the main
    // stack whenever the user clears all of his/her data.
    IrmaRepository.get().getEvents().where((event) => event is ClearAllDataEvent).listen((_) {
      _navigatorKey.currentState.pushNamedAndRemoveUntil(EnrollmentScreen.routeName, (_) => false);
    });
  }

  Future<void> _maybeOpenQrScanner() async {
    // Push the QR scanner screen if the preference is enabled
    final startQrScanner = await IrmaPreferences.get().getStartQRScan().first;
    // Check if the app was started with a HandleURLEvent or resumed when returning from in-app browser.
    // If so, do not open the QR scanner.
    final appResumedAutomatically = await IrmaRepository.get().appResumedAutomatically();
    if (startQrScanner && !appResumedAutomatically && !_qrScannerActive) {
      _navigatorKey.currentState.pushNamed(ScannerScreen.routeName);
    }
  }

  void _startSession(SessionPointer sessionPointer) {
    if (sessionPointer.wizard != null) {
      ScannerScreen.startIssueWizard(navigator, sessionPointer);
    } else {
      ScannerScreen.startSessionAndNavigate(_navigatorKey.currentState, sessionPointer);
    }
  }

  Widget _buildPinScreen(bool isLocked) {
    // Display nothing if we are not locked
    if (!isLocked) return Container();
    // We use a navigator here, instead of just rendering the pin screen
    //  to give error screens a place to go.
    return HeroControllerScope(
      controller: createHeroController(),
      child: Navigator(
        initialRoute: PinScreen.routeName,
        onGenerateRoute: (settings) {
          // Render `RouteNotFoundScreen` when trying to render named route that
          // is not pinscreen on this stack
          WidgetBuilder screenBuilder = (context) => const RouteNotFoundScreen();
          if (settings.name == PinScreen.routeName) {
            screenBuilder = (context) => const PinScreen();
          } else if (settings.name == ResetPinScreen.routeName) {
            screenBuilder = (context) => ResetPinScreen();
          }

          // Wrap in popscope
          return MaterialPageRoute(
            builder: (BuildContext context) {
              return WillPopScope(
                onWillPop: () async {
                  // On the pinscreen, background instead of pop
                  if (settings.name == PinScreen.routeName) {
                    IrmaRepository.get().bridgedDispatch(AndroidSendToBackgroundEvent());
                    return false;
                  } else {
                    return true;
                  }
                },
                child: screenBuilder(context),
              );
            },
            settings: settings,
          );
        },
      ),
    );
  }

  Widget _buildSplash(EnrollmentStatus enrollmentStatus) {
    if (_removeSplash) {
      return Container();
    }

    // In case of a fatal error, we have to lift the splash to make the error visible.
    return StreamBuilder(
      stream: IrmaRepository.get().getFatalErrors(),
      builder: (context, fatalError) => AnimatedOpacity(
        opacity: !fatalError.hasData && (enrollmentStatus == EnrollmentStatus.undetermined || _showSplash) ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 500),
        onEnd: () {
          setState(() {
            _removeSplash = true;
          });
        },
        child: const SplashScreen(),
      ),
    );
  }

  Stream<bool> _displayDeviceIsRootedWarning() {
    final streamController = StreamController<bool>();
    _detectRootedDeviceRepo.isDeviceRooted().then((isRooted) {
      if (isRooted) {
        _detectRootedDeviceRepo
            .hasAcceptedRootedDeviceRisk()
            .map((acceptedRisk) => !acceptedRisk)
            .pipe(streamController);
      } else {
        streamController.add(false);
      }
    });
    return streamController.stream;
  }

  Widget _buildAppOverlay(BuildContext context, EnrollmentStatus enrollmentStatus) {
    final repo = IrmaRepository.get();
    return StreamBuilder<CombinedState3<bool, VersionInformation, bool>>(
      stream: combine3(_displayDeviceIsRootedWarning(), repo.getVersionInformation(), repo.getLocked()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildSplash(enrollmentStatus);
        }

        final displayRootedWarning = snapshot.data.a;
        if (displayRootedWarning) {
          return RootedWarningScreen(
            onAcceptRiskButtonPressed: () async {
              _detectRootedDeviceRepo.setHasAcceptedRootedDeviceRisk();
            },
          );
        }

        final versionInformation = snapshot.data.b;
        if (versionInformation != null && versionInformation.updateRequired()) {
          return RequiredUpdateScreen();
        }

        final isLocked = snapshot.data.c;
        return _buildPinScreen(isLocked);
      },
    );
  }

  Widget _buildAppStack(
    BuildContext context,
    Widget navigationChild,
    EnrollmentStatus enrollmentStatus,
  ) {
    // Use this Stack to force an overlay when loading and when an update is required.
    return Stack(
      children: <Widget>[
        navigationChild,
        _buildAppOverlay(context, enrollmentStatus),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final irmaRepo = IrmaRepository.get();
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

            return Stack(
              textDirection: TextDirection.ltr,
              children: <Widget>[
                MaterialApp(
                  key: const Key("app"),
                  title: 'IRMA',
                  theme: IrmaTheme.of(context).themeData,
                  localizationsDelegates: defaultLocalizationsDelegates(),
                  supportedLocales: defaultSupportedLocales(),
                  navigatorKey: _navigatorKey,
                  navigatorObservers: [this],
                  onGenerateRoute: Routing.generateRoute,

                  // Set showSemanticsDebugger to true to view semantics in emulator.
                  showSemanticsDebugger: false,

                  builder: (context, child) {
                    return _buildAppStack(context, child, enrollmentStatus);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
