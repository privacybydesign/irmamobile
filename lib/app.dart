import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_privacy_screen/flutter_privacy_screen.dart';
import 'package:rxdart/rxdart.dart';

import '../../routing.dart';
import '../../src/data/irma_repository.dart';
import '../../src/models/applifecycle_changed_event.dart';
import '../../src/models/clear_all_data_event.dart';
import '../../src/models/enrollment_status.dart';
import '../../src/models/event.dart';
import '../../src/models/native_events.dart';
import '../../src/models/session.dart';
import '../../src/models/update_schemes_event.dart';
import '../../src/models/version_information.dart';
import '../../src/screens/enrollment/enrollment_screen.dart';
import '../../src/screens/pin/pin_screen.dart';
import '../../src/screens/required_update/required_update_screen.dart';
import '../../src/screens/reset_pin/reset_pin_screen.dart';
import '../../src/screens/rooted_warning/repository.dart';
import '../../src/screens/rooted_warning/rooted_warning_screen.dart';
import '../../src/screens/splash_screen/splash_screen.dart';
import '../../src/theme/theme.dart';
import '../../src/util/combine.dart';
import 'src/screens/name_changed/name_changed_screen.dart';
import 'src/screens/notifications/bloc/notifications_bloc.dart';
import 'src/screens/scanner/util/open_scanner.dart';
import 'src/widgets/irma_repository_provider.dart';

const schemeUpdateIntervalHours = 3;

class App extends StatefulWidget {
  final IrmaRepository irmaRepository;
  final Locale? forcedLocale;
  final NotificationsBloc notificationsBloc;

  const App({
    super.key,
    required this.irmaRepository,
    required this.notificationsBloc,
    this.forcedLocale,
  });

  @override
  AppState createState() => AppState();
}

class AppState extends State<App> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final DetectRootedDeviceIrmaPrefsRepository _detectRootedDeviceRepo;

  StreamSubscription<Pointer?>? _pointerSubscription;
  StreamSubscription<Event>? _dataClearSubscription;
  StreamSubscription<bool>? _screenshotPrefSubscription;
  StreamSubscription<EnrollmentStatus>? _enrollmentStatusSubscription;
  bool _privacyScreenLoaded = false;

  // We keep track of the last two life cycle states
  // to be able to determine the flow
  List<AppLifecycleState> prevLifeCycleStates = List.filled(2, AppLifecycleState.detached);

  AppState();

  static List<LocalizationsDelegate> defaultLocalizationsDelegates([Locale? forcedLocale]) => [
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

  static List<Locale> defaultSupportedLocales() {
    return const [
      Locale('en', 'US'),
      Locale('nl', 'NL'),
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenForDataClear();
    _listenScreenshotPref();
    _handleUpdateSchemes();
    _listenShowNameChangedNotification();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pointerSubscription?.cancel();
    _dataClearSubscription?.cancel();
    _screenshotPrefSubscription?.cancel();
    _enrollmentStatusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _listenShowNameChangedNotification() async {
    final showNameChangedNotification = await widget.irmaRepository.preferences.getShowNameChangedNotification().first;

    if (showNameChangedNotification) {
      _enrollmentStatusSubscription = widget.irmaRepository.getEnrollmentStatus().listen((event) {
        // If the user is unenrolled we never want to show the name changed notification again
        if (event == EnrollmentStatus.unenrolled) {
          widget.irmaRepository.preferences.setShowNameChangedNotification(false);
          _enrollmentStatusSubscription?.cancel();
        }
      });
    }
  }

  Future<void> _handleUpdateSchemes() async {
    final lastSchemeUpdate = await widget.irmaRepository.preferences.getLastSchemeUpdate().first;

    if (DateTime.now().difference(lastSchemeUpdate).inHours > schemeUpdateIntervalHours) {
      widget.irmaRepository.preferences.setLastSchemeUpdate(DateTime.now());
      widget.irmaRepository.bridgedDispatch(UpdateSchemesEvent());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // only init _detectRootedDeviceRepo once...
    try {
      _detectRootedDeviceRepo;
    } catch (_) {
      final repo = IrmaRepositoryProvider.of(context);
      _detectRootedDeviceRepo = DetectRootedDeviceIrmaPrefsRepository(preferences: repo.preferences);
    }
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    widget.irmaRepository.dispatch(AppLifecycleChangedEvent(state));

    // Resumed = when the app regains focus after being inactive or paused in the background
    if (state == AppLifecycleState.resumed) {
      _handleUpdateSchemes();
      widget.notificationsBloc.add(LoadNotifications());
    }

    // We check the transition goes from paused -> inactive -> resumed
    // because the transition inactive -> resumed can also happen
    // in scenarios where the app is not closed. Like an apple pay
    // authentication request or a phone call that interrupts
    // the app but doesn't pause it. In those cases we don't open
    // the QR scanner.
    // Note: on some phones, the events arrive in the other order
    // (inactive -> paused), so we just check that both of them are
    // present in prevLifeCycleStates (which is of size 2).
    if (prevLifeCycleStates.contains(AppLifecycleState.paused) &&
        prevLifeCycleStates.contains(AppLifecycleState.inactive) &&
        state == AppLifecycleState.resumed) {
      // First check whether we should redo pin verification
      final lastActive = await widget.irmaRepository.getLastActiveTime().first;
      final status = await widget.irmaRepository
          .getEnrollmentStatus()
          .firstWhere((status) => status != EnrollmentStatus.undetermined);
      final locked = await widget.irmaRepository.getLocked().first;
      if (status == EnrollmentStatus.enrolled) {
        if (!locked && lastActive.isBefore(DateTime.now().subtract(const Duration(minutes: 5)))) {
          widget.irmaRepository.lock();
        } else {
          maybeOpenQrScanner(
            widget.irmaRepository,
            _navigatorKey.currentState!,
          );
        }
      }
    }

    // TODO: Use this detection also to reset the _showSplash and _removeSplash
    // variables.
    prevLifeCycleStates[0] = prevLifeCycleStates[1];
    prevLifeCycleStates[1] = state;
  }

  void _listenForDataClear() {
    // Clearing all data can be done both from the pin entry screen, or from
    // the settings screen. As these are on different navigation stacks entirely,
    // we cannot there manipulate the desired navigation stack for the enrollment
    // screen. Hence, we do that here, pushing the enrollment screen on the main
    // stack whenever the user clears all of his/her data.
    _dataClearSubscription = widget.irmaRepository.getEvents().where((event) => event is ClearAllDataEvent).listen((_) {
      _navigatorKey.currentState?.pushNamedAndRemoveUntil(EnrollmentScreen.routeName, (_) => false);
    });
  }

  Widget _buildPinScreen() {
    // We use a navigator here, instead of just rendering the pin screen
    //  to give error screens a place to go.
    return HeroControllerScope(
      controller: MaterialApp.createMaterialHeroController(),
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
              return PopScope(
                canPop: settings.name != PinScreen.routeName,
                onPopInvokedWithResult: (didPop, popResult) {
                  // On the pin screen, background instead of pop
                  if (!didPop) {
                    widget.irmaRepository.bridgedDispatch(AndroidSendToBackgroundEvent());
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

  void _listenScreenshotPref() {
    // We only wait for the privacy screen to be loaded on start-up.
    _privacyScreenLoaded = false;
    _screenshotPrefSubscription = widget.irmaRepository.preferences.getScreenshotsEnabled().listen((enabled) async {
      if (enabled) {
        await FlutterPrivacyScreen.disablePrivacyScreen();
      } else {
        await FlutterPrivacyScreen.enablePrivacyScreen();
      }
      if (!_privacyScreenLoaded) setState(() => _privacyScreenLoaded = true);
    });
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

  Widget _buildAppOverlay(BuildContext context) {
    return StreamBuilder<CombinedState4<bool, VersionInformation?, bool, bool>>(
      stream: combine4(
        _displayDeviceIsRootedWarning(),
        // combine3 cannot handle empty streams, so we have to make sure always a value is present.
        widget.irmaRepository
            .getVersionInformation()
            .map<VersionInformation?>((version) => version)
            .defaultIfEmpty(null),
        widget.irmaRepository.getLocked(),
        widget.irmaRepository.preferences.getShowNameChangedNotification(),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !_privacyScreenLoaded) {
          // Delay the loading indicator a bit, so it doesn't flash on screen.
          return FutureBuilder(
            future: Future.delayed(const Duration(seconds: 3), () => true),
            builder: (context, isLoading) => SplashScreen(isLoading: isLoading.data ?? false),
          );
        }

        final displayRootedWarning = snapshot.data!.a;
        if (displayRootedWarning) {
          return RootedWarningScreen(
            onAcceptRiskButtonPressed: () async {
              _detectRootedDeviceRepo.setHasAcceptedRootedDeviceRisk();
            },
          );
        }

        final showNameChangedNotification = snapshot.data!.d;
        if (showNameChangedNotification) {
          return NameChangedScreen(
            onContinuePressed: () => widget.irmaRepository.preferences.setShowNameChangedNotification(false),
          );
        }

        final versionInformation = snapshot.data!.b;
        if (versionInformation != null && versionInformation.updateRequired()) {
          return RequiredUpdateScreen();
        }

        final isLocked = snapshot.data!.c;
        if (isLocked) {
          return _buildPinScreen();
        }

        // There is no need for an overlay; the underlying screen can be shown.
        return Container();
      },
    );
  }

  Widget _buildAppStack(BuildContext context, Widget navigationChild) {
    // Use this Stack to force an overlay when loading and when an update is required.
    return Stack(
      children: <Widget>[
        navigationChild,
        _buildAppOverlay(context),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    return IrmaTheme(
      builder: (BuildContext context) {
        return Stack(
          textDirection: TextDirection.ltr,
          children: <Widget>[
            MaterialApp(
              key: const Key('app'),
              title: 'Yivi',
              theme: IrmaTheme.of(context).themeData,
              localizationsDelegates: defaultLocalizationsDelegates(
                widget.forcedLocale,
              ),
              supportedLocales: defaultSupportedLocales(),
              navigatorKey: _navigatorKey,
              onGenerateRoute: Routing.generateRoute,

              // Set showSemanticsDebugger to true to view semantics in emulator.
              showSemanticsDebugger: false,

              builder: (context, child) {
                if (child == null) return const SplashScreen(); // Fallback value, should never happen.
                return _buildAppStack(context, child);
              },
            ),
          ],
        );
      },
    );
  }
}
