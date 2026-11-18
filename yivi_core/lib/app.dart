import "dart:async";

import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../routing.dart";
import "../../src/models/applifecycle_changed_event.dart";
import "../../src/models/enrollment_status.dart";
import "../../src/models/event.dart";
import "../../src/models/session.dart";
import "../../src/models/update_schemes_event.dart";
import "../../src/theme/theme.dart";
import "package_name.dart";
import "src/data/irma_preferences.dart";
import "src/providers/irma_repository_provider.dart";
import "src/providers/preferences_provider.dart";
import "src/screens/data/card_transition/card_transition.dart";
import "src/screens/home/widgets/system_navigation_bar.dart";
import "src/screens/notifications/notifications_provider.dart";
import "src/screens/pin/lock_gate.dart";
import "src/screens/review/store_review_gate.dart";
import "src/util/idle_lock_observer.dart";
import "src/util/privacy_screen.dart";
import "src/widgets/legacy_material_bridge.dart";
import "src/widgets/scroll_to_top.dart";
import "src/widgets/side_panel_inset.dart";
import "src/widgets/unfocus_on_tap_outside.dart";

const schemeUpdateIntervalHours = 3;

class App extends ConsumerStatefulWidget {
  final Locale? forcedLocale;
  final Duration? idleLockThreshold;

  const App({super.key, this.forcedLocale, this.idleLockThreshold});

  @override
  ConsumerState<App> createState() => AppState();
}

class AppState extends ConsumerState<App> with WidgetsBindingObserver {
  StreamSubscription<Pointer?>? _pointerSubscription;
  StreamSubscription<Event>? _dataClearSubscription;
  StreamSubscription<bool>? _screenshotPrefSubscription;
  StreamSubscription<Appearance>? _appearanceSubscription;
  StreamSubscription<EnrollmentStatus>? _enrollmentStatusSubscription;
  bool _privacyScreenLoaded = false;
  var _appearance = Appearance.system;

  AppState();

  static List<LocalizationsDelegate> defaultLocalizationsDelegates([
    Locale? forcedLocale,
  ]) {
    return [
      FlutterI18nDelegate(
        translationLoader: FileTranslationLoader(
          fallbackFile: "en",
          basePath: yiviAsset("locales"),
          forcedLocale: forcedLocale,
        ),
      ),
      ...GlobalMaterialLocalizations.delegates,
    ];
  }

  static List<Locale> defaultSupportedLocales() {
    return const [Locale("en", "US"), Locale("nl", "NL"), Locale("de", "DE")];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenScreenshotPref();
    _appearanceSubscription = ref
        .read(preferencesProvider)
        .appearance
        .stream
        .listen((appearance) {
          if (mounted && appearance != _appearance) {
            setState(() => _appearance = appearance);
          }
        });
    _handleUpdateSchemes();
    _listenShowNameChangedNotification();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pointerSubscription?.cancel();
    _dataClearSubscription?.cancel();
    _screenshotPrefSubscription?.cancel();
    _appearanceSubscription?.cancel();
    _enrollmentStatusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _listenShowNameChangedNotification() async {
    final repo = ref.read(irmaRepositoryProvider);
    final prefs = ref.read(preferencesProvider);

    final showNameChangedNotification =
        await prefs.showNameChangedNotification.stream.first;

    if (showNameChangedNotification) {
      _enrollmentStatusSubscription = repo.getEnrollmentStatus().listen((
        event,
      ) {
        // If the user is unenrolled we never want to show the name changed notification again
        if (event == EnrollmentStatus.unenrolled) {
          repo.preferences.showNameChangedNotification.set(false);
          _enrollmentStatusSubscription?.cancel();
        }
      });
    }
  }

  Future<void> _handleUpdateSchemes() async {
    final repo = ref.read(irmaRepositoryProvider);
    final prefs = ref.read(preferencesProvider);
    final lastSchemeUpdate = await prefs.lastSchemeUpdate.stream.first;

    if (DateTime.now().difference(lastSchemeUpdate).inHours >
        schemeUpdateIntervalHours) {
      prefs.lastSchemeUpdate.set(DateTime.now());
      repo.bridgedDispatch(UpdateSchemesEvent());
    }
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    final repo = ref.read(irmaRepositoryProvider);
    repo.dispatch(AppLifecycleChangedEvent(state));

    if (state == AppLifecycleState.resumed) {
      _handleUpdateSchemes();
      ref.read(notificationsProvider.notifier).reload();
    }
  }

  void _listenScreenshotPref() {
    final prefs = ref.read(preferencesProvider);
    // We only wait for the privacy screen to be loaded on start-up.
    _privacyScreenLoaded = false;
    _screenshotPrefSubscription = prefs.screenshotsEnabled.stream.listen((
      enabled,
    ) async {
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
    final router = ref.watch(routerProvider);
    return IrmaTheme(
      builder: (BuildContext context) {
        return IdleLockObserver(
          idleThreshold: widget.idleLockThreshold ?? const Duration(minutes: 5),
          child: MaterialApp.router(
            key: const Key("app"),
            title: "Yivi",
            theme: IrmaTheme.variantsOf(context).data.themeData,
            darkTheme: IrmaTheme.variantsOf(context).darkData.themeData,
            themeMode: switch (_appearance) {
              Appearance.system => ThemeMode.system,
              Appearance.light => ThemeMode.light,
              Appearance.dark => ThemeMode.dark,
            },
            localizationsDelegates: defaultLocalizationsDelegates(
              widget.forcedLocale,
            ),
            supportedLocales: defaultSupportedLocales(),
            showSemanticsDebugger: false,
            routerConfig: router,
            // Beside a panel down the side of an upright screen; a tap
            // outside a text field puts the keyboard away.
            // Above the navigator: a card opening from the stack runs over
            // the home page and its details page both.
            builder: (context, child) => CardTransitions(
              child: StatusBarScrollsToTop(
                child: SidePanelInset(
                  child: UnfocusOnTapOutside(
                    child: LegacyMaterialBridge(
                      child: LockGate(
                        child: StoreReviewGate(
                          child: SystemNavigationBarStyle(
                            child: child ?? const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
