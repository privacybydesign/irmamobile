import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../routing.dart';
import '../../src/models/applifecycle_changed_event.dart';
import '../../src/models/enrollment_status.dart';
import '../../src/models/event.dart';
import '../../src/models/session.dart';
import '../../src/models/update_schemes_event.dart';
import '../../src/screens/rooted_warning/repository.dart';
import '../../src/theme/theme.dart';
import 'src/providers/irma_repository_provider.dart';
import 'src/providers/preferences_provider.dart';
import 'src/screens/notifications/bloc/notifications_bloc.dart';
import 'src/util/privacy_screen.dart';

const schemeUpdateIntervalHours = 3;

class App extends ConsumerStatefulWidget {
  final Locale? forcedLocale;
  final NotificationsBloc notificationsBloc;

  const App({
    super.key,
    required this.notificationsBloc,
    this.forcedLocale,
  });

  @override
  ConsumerState<App> createState() => AppState();
}

class AppState extends ConsumerState<App> with WidgetsBindingObserver {
  late final DetectRootedDeviceIrmaPrefsRepository _detectRootedDeviceRepo;

  StreamSubscription<Pointer?>? _pointerSubscription;
  StreamSubscription<Event>? _dataClearSubscription;
  StreamSubscription<bool>? _screenshotPrefSubscription;
  StreamSubscription<EnrollmentStatus>? _enrollmentStatusSubscription;
  bool _privacyScreenLoaded = false;

  // TODO: When switching to Riverpod we should add a provider for the
  // router, as that will automatically preserve its state during rebuilds.
  // This method is kind of a workaround for now.
  late final GoRouter _router;

  // We keep track of the last two life cycle states
  // to be able to determine the flow
  List<AppLifecycleState> prevLifeCycleStates = List.filled(2, AppLifecycleState.detached);

  AppState();

  static List<LocalizationsDelegate> defaultLocalizationsDelegates([Locale? forcedLocale]) {
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    final repo = ref.read(irmaRepositoryProvider);
    final prefs = ref.read(preferencesProvider);

    final showNameChangedNotification = await prefs.getShowNameChangedNotification().first;

    if (showNameChangedNotification) {
      _enrollmentStatusSubscription = repo.getEnrollmentStatus().listen((event) {
        // If the user is unenrolled we never want to show the name changed notification again
        if (event == EnrollmentStatus.unenrolled) {
          repo.preferences.setShowNameChangedNotification(false);
          _enrollmentStatusSubscription?.cancel();
        }
      });
    }
  }

  Future<void> _handleUpdateSchemes() async {
    final repo = ref.read(irmaRepositoryProvider);
    final prefs = ref.read(preferencesProvider);
    final lastSchemeUpdate = await prefs.getLastSchemeUpdate().first;

    if (DateTime.now().difference(lastSchemeUpdate).inHours > schemeUpdateIntervalHours) {
      prefs.setLastSchemeUpdate(DateTime.now());
      repo.bridgedDispatch(UpdateSchemesEvent());
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
      _router = createRouter(context, ref);
    }
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    final repo = ref.read(irmaRepositoryProvider);
    repo.dispatch(AppLifecycleChangedEvent(state));

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
      final status = await repo.getEnrollmentStatus().firstWhere((status) => status != EnrollmentStatus.undetermined);
      // First check whether we should redo pin verification
      final lastActive = await repo.getLastActiveTime().first;
      final locked = await repo.getLocked().first;

      if (status == EnrollmentStatus.enrolled) {
        if (!locked && lastActive.isBefore(DateTime.now().subtract(const Duration(minutes: 5)))) {
          repo.lock();
        }
      }
    }

    // TODO: Use this detection also to reset the _showSplash and _removeSplash
    // variables.
    prevLifeCycleStates[0] = prevLifeCycleStates[1];
    prevLifeCycleStates[1] = state;
  }

  void _listenScreenshotPref() {
    final prefs = ref.read(preferencesProvider);
    // We only wait for the privacy screen to be loaded on start-up.
    _privacyScreenLoaded = false;
    _screenshotPrefSubscription = prefs.getScreenshotsEnabled().listen((enabled) async {
      if (enabled) {
        await PrivacyScreen.disablePrivacyScreen();
      } else {
        await PrivacyScreen.enablePrivacyScreen();
      }
      if (!_privacyScreenLoaded) setState(() => _privacyScreenLoaded = true);
    });
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
        return MaterialApp.router(
          key: const Key('app'),
          title: 'Yivi',
          theme: IrmaTheme.of(context).themeData,
          localizationsDelegates: defaultLocalizationsDelegates(widget.forcedLocale),
          supportedLocales: defaultSupportedLocales(),
          showSemanticsDebugger: false,
          routerConfig: _router,
        );
      },
    );
  }
}
