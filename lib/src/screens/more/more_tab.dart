import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../providers/irma_repository_provider.dart';
import '../../theme/theme.dart';
import '../../util/navigation.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/translated_text.dart';
import '../../widgets/yivi_themed_button.dart';
import '../home/widgets/irma_nav_bar.dart';
import 'widgets/tiles.dart';
import 'widgets/tiles_card.dart';
import 'widgets/version_button.dart';

class MoreTab extends StatefulWidget {
  final Function(IrmaNavBarTab tab) onChangeTab;

  const MoreTab({required this.onChangeTab});

  @override
  State<MoreTab> createState() => _MoreTabState();
}

class _MoreTabState extends State<MoreTab> {
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
    final theme = IrmaTheme.of(context);

    final spacerWidget = SizedBox(height: theme.mediumSpacing);

    Widget buildHeaderText(String translationKey) => Padding(
      padding: EdgeInsets.only(bottom: theme.smallSpacing),
      child: TranslatedText(
        translationKey,
        isHeader: true,
        style: theme.textTheme.bodyLarge!.copyWith(color: theme.neutralExtraDark),
      ),
    );

    return Scaffold(
      backgroundColor: IrmaTheme.of(context).backgroundTertiary,
      appBar: IrmaAppBar(titleTranslationKey: 'home.nav_bar.more', leading: null),
      body: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(theme.defaultSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(sortKey: const OrdinalSortKey(0), child: buildHeaderText('more_tab.app_management')),
            TilesCard(
              children: [
                InternalLinkTile(
                  key: Key('open_settings_screen_button'),
                  labelTranslationKey: 'more_tab.settings',
                  iconData: Icons.settings_outlined,
                  onTap: context.goSettingsScreen,
                ),
                InternalLinkTile(
                  labelTranslationKey: 'more_tab.faq',
                  iconData: Icons.help_outline_rounded,
                  onTap: context.goHelpScreen,
                ),
                if (showDebugging)
                  InternalLinkTile(
                    labelTranslationKey: 'more_tab.debugging',
                    iconData: Icons.code_rounded,
                    onTap: context.goDebugScreen,
                  ),
              ],
            ),
            spacerWidget,
            buildHeaderText('help.about_irma'),
            const TilesCard(
              children: [
                ExternalLinkTile(
                  labelTranslationKey: 'more_tab.website',
                  iconData: Icons.info_outline_rounded,
                  urlLinkKey: 'more_tab.irma_website_link',
                ),
                ContactLinkTile(labelTranslationKey: 'more_tab.contact', iconData: Icons.mail_outline_rounded),
              ],
            ),
            spacerWidget,
            buildHeaderText('more_tab.slogan'),
            const TilesCard(
              children: [
                ShareLinkTile(
                  iconData: Icons.share_outlined,
                  labelTranslationKey: 'more_tab.share',
                  shareTextKey: 'more_tab.share_text',
                ),
                ExternalLinkTile(
                  iconData: Icons.description_outlined,
                  labelTranslationKey: 'more_tab.privacy_policy',
                  urlLinkKey: 'more_tab.privacy_policy_link',
                ),
              ],
            ),
            spacerWidget,
            YiviThemedButton(
              key: const Key('log_out_button'),
              style: YiviButtonStyle.filled,
              label: 'more_tab.log_out',
              onPressed: () {
                IrmaRepositoryProvider.of(context).lock();
                widget.onChangeTab(IrmaNavBarTab.data);
              },
            ),
            spacerWidget,
            const VersionButton(),
          ],
        ),
      ),
    );
  }
}
