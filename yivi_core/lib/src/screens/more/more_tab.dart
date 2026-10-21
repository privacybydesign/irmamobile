import "dart:async";

import "package:flutter/semantics.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../providers/irma_repository_provider.dart";
import "../../providers/pane_selection_provider.dart";
import "../../theme/yivi_palette.dart";
import "../../util/adaptive_layout.dart";
import "../../util/navigation.dart";
import "../../widgets/glass/pill_buttons.dart";
import "../../widgets/glass/title_scroll_edge.dart";
import "../../widgets/lock_gate.dart";
import "../../widgets/translated_text.dart";
import "../../widgets/two_pane.dart";
import "../help/help_screen.dart";
import "../home/widgets/irma_nav_bar.dart";
import "../settings/settings_screen.dart";
import "widgets/tiles.dart";
import "widgets/tiles_card.dart";
import "widgets/version_button.dart";

class MoreTab extends ConsumerStatefulWidget {
  final Function(IrmaNavBarTab tab) onChangeTab;

  const MoreTab({required this.onChangeTab});

  @override
  ConsumerState<MoreTab> createState() => _MoreTabState();
}

class _MoreTabState extends ConsumerState<MoreTab> {
  StreamSubscription? _devModeSubscription;
  bool showDebugging = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final repo = IrmaRepositoryProvider.of(context);
      _devModeSubscription = repo.getDeveloperMode().listen((event) {
        setState(() {
          showDebugging = event;
        });
      });
    });
  }

  @override
  void dispose() {
    _devModeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final padding = MediaQuery.paddingOf(context);
    // Held sideways Instellingen and Veelgestelde vragen open in a pane
    // beside the list (Instellingen until another is picked).
    final withPane = usePhoneLandscape(context);
    final page = ref.watch(selectedMorePageProvider) ?? MorePage.settings;
    void open(MorePage p, VoidCallback push) => withPane
        ? ref.read(selectedMorePageProvider.notifier).select(p)
        : push();

    Widget buildHeaderText(String translationKey) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Semantics(
        header: true,
        child: TranslatedText(translationKey, style: palette.display(16)),
      ),
    );

    // In the tablet layout the sections sit in two columns.
    final expanded = isExpandedLayout(context);
    final appManagement = <Widget>[
      Semantics(
        sortKey: const OrdinalSortKey(0),
        child: buildHeaderText("more_tab.app_management"),
      ),
      TilesCard(
        children: [
          InternalLinkTile(
            key: Key("open_settings_screen_button"),
            labelTranslationKey: "more_tab.settings",
            iconData: Icons.settings_outlined,
            selected: withPane && page == MorePage.settings,
            onTap: () => open(MorePage.settings, context.goSettingsScreen),
          ),
          InternalLinkTile(
            key: const Key("open_help_screen_button"),
            labelTranslationKey: "more_tab.faq",
            iconData: Icons.help_outline_rounded,
            selected: withPane && page == MorePage.faq,
            onTap: () => open(MorePage.faq, context.goHelpScreen),
          ),
          if (showDebugging)
            InternalLinkTile(
              labelTranslationKey: "more_tab.debugging",
              iconData: Icons.code_rounded,
              onTap: context.goDebugScreen,
            ),
        ],
      ),
    ];
    final about = <Widget>[
      buildHeaderText("help.about_irma"),
      const TilesCard(
        children: [
          ExternalLinkTile(
            labelTranslationKey: "more_tab.website",
            iconData: Icons.info_outline_rounded,
            urlLinkKey: "more_tab.irma_website_link",
          ),
          ContactLinkTile(
            labelTranslationKey: "more_tab.contact",
            iconData: Icons.mail_outline_rounded,
          ),
        ],
      ),
      buildHeaderText("more_tab.slogan"),
      const TilesCard(
        children: [
          ShareLinkTile(
            iconData: Icons.share_outlined,
            labelTranslationKey: "more_tab.share",
            shareTextKey: "more_tab.share_text",
          ),
          ExternalLinkTile(
            iconData: Icons.description_outlined,
            labelTranslationKey: "more_tab.privacy_policy",
            urlLinkKey: "more_tab.privacy_policy_link",
          ),
        ],
      ),
    ];

    // The large title's bottom: 24 + 8 above it, about 34 for itself.
    final list = TitleScrollEdge(
      title: FlutterI18n.translate(context, "home.nav_bar.more"),
      largeTitleBottom: 24 + 8 + 34,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          16,
          // Held sideways the title starts level with the search field of
          // the other tabs (12 from the top).
          padding.top + (usePhoneLandscape(context) ? 4 : 24),
          16,
          padding.bottom + bottomBarSpace(context),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: expanded ? 960 : 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                  child: Semantics(
                    header: true,
                    child: TranslatedText(
                      "home.nav_bar.more",
                      style: palette.display(26, weight: FontWeight.w700),
                    ),
                  ),
                ),
                if (expanded)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 24,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: appManagement,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: about,
                        ),
                      ),
                    ],
                  )
                else ...[
                  ...appManagement,
                  ...about,
                ],
                const SizedBox(height: 32),
                PillButton(
                  key: const Key("log_out_button"),
                  style: PillStyle.neutral,
                  label: FlutterI18n.translate(context, "more_tab.log_out"),
                  onPressed: () {
                    // Confirm the deliberate logout so the user understands they
                    // were logged out and the PIN screen is not asking for a PIN in
                    // order to log out. Shown by the lock overlay rather than from
                    // here: on this tab's ScaffoldMessenger the snackbar also paints
                    // in this Scaffold, which stays mounted under the overlay.
                    confirmLogoutOnNextLock = true;
                    // userInitiated: skip the "scan on launch" auto-biometric on
                    // the lock screen that follows an explicit logout.
                    IrmaRepositoryProvider.of(
                      context,
                    ).lock(userInitiated: true);
                    widget.onChangeTab(IrmaNavBarTab.data);
                  },
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: VersionButton(),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: palette.background,
      body: withPane
          ? TwoPane(
              list: list,
              detail: switch (page) {
                MorePage.settings => const SettingsScreen(
                  key: Key("more_pane_settings"),
                  embedded: true,
                ),
                MorePage.faq => const HelpScreen(
                  key: Key("more_pane_faq"),
                  embedded: true,
                ),
              },
            )
          : list,
    );
  }
}
