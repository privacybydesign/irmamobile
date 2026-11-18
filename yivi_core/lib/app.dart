import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../routing.dart";
import "../../src/theme/theme.dart";
import "package_name.dart";
import "src/data/irma_preferences.dart";
import "src/providers/app_effects.dart";
import "src/providers/preferences_provider.dart";
import "src/screens/data/card_transition/card_transition.dart";
import "src/screens/home/widgets/system_navigation_bar.dart";
import "src/screens/pin/lock_gate.dart";
import "src/screens/review/store_review_gate.dart";
import "src/widgets/bars/scroll_to_top.dart";
import "src/widgets/input/unfocus_on_tap_outside.dart";
import "src/widgets/layout/legacy_material_bridge.dart";
import "src/widgets/layout/side_panel_inset.dart";

class App extends ConsumerStatefulWidget {
  final Locale? forcedLocale;

  const App({super.key, this.forcedLocale});

  @override
  ConsumerState<App> createState() => AppState();
}

class AppState extends ConsumerState<App> {
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
  Widget build(BuildContext context) {
    // What the app does by itself, outside any screen.
    ref.watch(privacyScreenProvider);
    ref.watch(schemeUpdateProvider);
    ref.watch(nameChangedResetProvider);
    ref.watch(idleLockProvider);
    final appearance = ref.watch(appearanceProvider);
    final router = ref.watch(routerProvider);
    return YiviTheme(
      builder: (BuildContext context) {
        return MaterialApp.router(
          key: const Key("app"),
          title: "Yivi",
          theme: YiviTheme.variantsOf(context).data.themeData,
          darkTheme: YiviTheme.variantsOf(context).darkData.themeData,
          themeMode: switch (appearance) {
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
        );
      },
    );
  }
}
