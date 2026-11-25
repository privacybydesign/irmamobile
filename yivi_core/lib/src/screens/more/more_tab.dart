import "package:flutter/semantics.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../providers/app_providers.dart";
import "../../providers/irma_repository_provider.dart";
import "../../providers/pane_selection_provider.dart";
import "../../routing/navigation.dart";
import "../../theme/yivi_palette.dart";
import "../../theme/yivi_space.dart";
import "../../util/adaptive_layout.dart";
import "../../util/i18n.dart";
import "../../widgets/bars/title_scroll_edge.dart";
import "../../widgets/buttons/pill_buttons.dart";
import "../../widgets/layout/centred_max_width.dart";
import "../../widgets/layout/tab_layout.dart";
import "../../widgets/layout/two_pane.dart";
import "../../widgets/surfaces/count_badge.dart";
import "../../widgets/surfaces/icon_square.dart";
import "../../widgets/surfaces/surface_card.dart";
import "../../widgets/text/section_header.dart";
import "../add_data/secure_app.dart";
import "../home/widgets/home_tab.dart";
import "../need_help/need_help_screen.dart";
import "../settings/settings_screen.dart";
import "widgets/tiles.dart";
import "widgets/tiles_card.dart";
import "widgets/version_button.dart";

class MoreTab extends ConsumerStatefulWidget {
  final Function(HomeTab tab) onChangeTab;

  const MoreTab({required this.onChangeTab});

  @override
  ConsumerState<MoreTab> createState() => _MoreTabState();
}

class _MoreTabState extends ConsumerState<MoreTab> {
  @override
  Widget build(BuildContext context) {
    final showDebugging = ref.watch(developerModeProvider);
    final palette = YiviPalette.of(context);
    // On a tablet and held sideways Instellingen and Hulp nodig? open in a
    // pane beside the list (Instellingen until another is picked).
    final withPane = useHomePanes(context);
    final page = ref.watch(selectedMorePageProvider) ?? MorePage.settings;
    void open(MorePage p, VoidCallback push) => withPane
        ? ref.read(selectedMorePageProvider.notifier).select(p)
        : push();

    Widget buildHeaderText(String translationKey) =>
        SectionHeader(context.tr(translationKey));

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
            key: const Key("open_need_help_button"),
            labelTranslationKey: "more_tab.need_help",
            iconData: Icons.support_outlined,
            selected: withPane && page == MorePage.needHelp,
            onTap: () => open(MorePage.needHelp, context.goNeedHelpScreen),
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

    final list = TitleScrollEdge(
      title: context.tr("home.nav_bar.more"),
      largeTitleBottom: tabTitleBottom,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: tabPagePadding(context),
        child: CentredMaxWidth(
          maxWidth: mediumContentMaxWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TabLargeTitle("home.nav_bar.more"),
              // Until an e-mail address is linked: on top, with a badge.
              if (ref.watch(setupUnfinishedProvider))
                const Padding(
                  padding: EdgeInsets.only(top: YiviSpace.x8),
                  child: _FinishSetupRow(),
                ),
              ...appManagement,
              ...about,
              const SizedBox(height: YiviSpace.x32),
              PillButton(
                key: const Key("log_out_button"),
                style: PillStyle.neutral,
                label: context.tr("more_tab.log_out"),
                onPressed: () {
                  // Confirm the deliberate logout so the user understands they
                  // were logged out and the PIN screen is not asking for a PIN in
                  // order to log out. Shown by the lock overlay rather than from
                  // here: on this tab's ScaffoldMessenger the snackbar also paints
                  // in this Scaffold, which stays mounted under the overlay.
                  // It also skips the "scan on launch" auto-biometric on the
                  // lock screen that follows an explicit logout.
                  ref.read(appLockProvider).logOut();
                  widget.onChangeTab(HomeTab.data);
                },
              ),
              const SizedBox(height: YiviSpace.x16),
              const Align(
                alignment: Alignment.centerLeft,
                child: VersionButton(),
              ),
            ],
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
                MorePage.needHelp => const NeedHelpScreen(
                  key: Key("more_pane_need_help"),
                  embedded: true,
                ),
              },
            )
          : list,
    );
  }
}

/// "Finish setting up Yivi": link an e-mail address, so the app can be
/// blocked if the phone is lost. Like "Finish setting up your iPhone": it
/// stays at the top of More, with a badge (and a dot on the tab), until an
/// address is linked.
class _FinishSetupRow extends StatelessWidget {
  const _FinishSetupRow();

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final title = context.tr("secure.finish.title");
    final text = context.tr("secure.finish.text");
    return Semantics(
      button: true,
      label: "$title, ${context.tr("secure.finish.todo")}. $text",
      excludeSemantics: true,
      child: SurfaceCard(
        key: const Key("more_finish_setup"),
        onTap: () => secureApp(context),
        padding: const EdgeInsets.all(YiviSpace.x16),
        child: Row(
          spacing: YiviSpace.x16,
          children: [
            IconSquare(
              icon: Icons.shield_outlined,
              fill: palette.infoSurface,
              ink: palette.link,
              size: 44,
              iconSize: 24,
              radius: 10,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: palette.display(16, weight: FontWeight.w600),
                  ),
                  Text(
                    text,
                    style: palette.rowSubtitle.copyWith(
                      color: palette.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            CountBadge(
              count: 1,
              fill: palette.primary,
              ink: Colors.white,
              size: 22,
              fontSize: 12,
              plus: false,
            ),
            Icon(Icons.chevron_right_rounded, color: palette.faint),
          ],
        ),
      ),
    );
  }
}
