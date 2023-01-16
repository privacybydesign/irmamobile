import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';


import '../../theme/irma_icons.dart';
import '../../theme/theme.dart';
import '../../widgets/irma_repository_provider.dart';
import '../../widgets/translated_text.dart';
import '../../widgets/yivi_themed_button.dart';
import '../home/widgets/irma_nav_bar.dart';

import 'widgets/grouped_links.dart';
import 'widgets/version_button.dart';

class MoreTab extends StatelessWidget {
  final Function(IrmaNavBarTab tab) onChangeTab;

  const MoreTab({required this.onChangeTab});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    Widget _buildHeaderText(String translationKey) => Padding(
          padding: EdgeInsets.all(theme.defaultSpacing),
          child: Semantics(
            header: true,
            child: TranslatedText(
              translationKey,
              style: theme.textTheme.headline4,
            ),
          ),
        );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderText('more_tab.app_management'),
          const GroupedLinks(
            children: [
              InternalLinkTile(
                labelTranslationKey: 'more_tab.settings',
                iconData: Icons.settings_outlined,
                routeName: '/settings',
              ),
              InternalLinkTile(
                labelTranslationKey: 'more_tab.faq',
                iconData: Icons.help_outline_rounded,
                routeName: '/help',
              ),
              if (kDebugMode)
                InternalLinkTile(
                  labelTranslationKey: 'more_tab.debugging',
                  iconData: Icons.code_rounded,
                  routeName: '/debug',
                ),
            ],
          ),
          _buildHeaderText('help.about_irma'),
          const GroupedLinks(
            children: [
              ExternalLinkTile(
                labelTranslationKey: 'more_tab.website',
                iconData: Icons.info_outline_rounded,
                urlLinkKey: 'more_tab.irma_website_link',
              ),
              ContactLinkTile(
                labelTranslationKey: 'more_tab.contact',
                iconData: Icons.mail_outline,
              )
            ],
          ),
          _buildHeaderText('more_tab.slogan'),

          const GroupedLinks(
            children: [
              ShareLinkTile(
                iconData: Icons.share,
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

    
 
          _buildHeaderText('more_tab.stay_informed'),

          const GroupedLinks(children: [
            ExternalLinkTile(
              iconData: Icons.groups_outlined,
              labelTranslationKey: 'more_tab.meetups',
              urlLinkKey: 'more_tab.meetups_link',
            ),
            ExternalLinkTile(
              iconData: IrmaIcons.twitter,
              labelTranslationKey: 'more_tab.twitter',
              urlLinkKey: 'more_tab.twitter_link',
            ),
            ExternalLinkTile(
              iconData: IrmaIcons.twitter,
              labelTranslationKey: 'more_tab.github',
              urlLinkKey: 'more_tab.github_link',
            )
          ]),

          Padding(
            padding: EdgeInsets.all(theme.defaultSpacing),
            child: YiviThemedButton(
              style: YiviButtonStyle.filled,
              label: 'more_tab.log_out',
              onPressed: () {
                IrmaRepositoryProvider.of(context).lock();
                onChangeTab(IrmaNavBarTab.home);
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(theme.defaultSpacing),
            child: VersionButton(),
          )
        ],
      ),
    );
  }
}
