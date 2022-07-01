import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:irmamobile/src/screens/home/widgets/links.dart';
import 'package:irmamobile/src/screens/more/widgets/version_button.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/translated_text.dart';

class MoreTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget _buildHeaderText(String translationKey) => Padding(
          padding: EdgeInsets.all(IrmaTheme.of(context).defaultSpacing),
          child: TranslatedText(
            translationKey,
            style: IrmaTheme.of(context).textTheme.headline3,
          ),
        );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const IrmaAppBar(
        titleTranslationKey: 'home.nav_bar.more',
        noLeading: true,
      ),
      Expanded(
        child: ListView(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          children: [
            _buildHeaderText('more_tab.app_management'),
            const InternalLink(
                key: Key('open_settings_screen_button'),
                iconData: Icons.settings_outlined,
                translationKey: 'more_tab.settings',
                routeName: '/settings'),
            const InternalLink(
                iconData: Icons.contact_support_outlined, translationKey: 'help.faq', routeName: '/help'),
            if (kDebugMode)
              const InternalLink(
                iconData: Icons.videogame_asset,
                translationKey: 'more_tab.debugging',
                routeName: '/debug',
              ),
            _buildHeaderText('help.about_irma'),
            const ExternalLink(
                iconData: Icons.info_outline,
                translationKey: 'more_tab.website',
                linkKey: 'more_tab.irma_website_link'),
            const ContactLink(iconData: Icons.mail_outline, translationKey: 'more_tab.contact'),
            _buildHeaderText('more_tab.slogan'),
            const ShareLink(
              iconData: Icons.share_outlined,
              translationKey: 'more_tab.share',
              shareTextKey: 'more_tab.share_text',
            ),
            const ExternalLink(
                iconData: Icons.description_outlined,
                translationKey: 'more_tab.privacy_policy',
                linkKey: 'enrollment.introduction.screen3.privacy.url'),
            _buildHeaderText('more_tab.stay_informed'),
            const ExternalLink(
                iconData: Icons.groups_outlined, translationKey: 'more_tab.meetups', linkKey: 'more_tab.meetups_link'),
            const ExternalLink(
                iconData: IrmaIcons.twitter, translationKey: 'more_tab.twitter', linkKey: 'more_tab.twitter_link'),
            const ExternalLink(
                iconData: IrmaIcons.github, translationKey: 'more_tab.github', linkKey: 'more_tab.github_link'),
            Padding(
              padding: EdgeInsets.all(IrmaTheme.of(context).defaultSpacing),
              child: VersionButton(),
            )
          ],
        ),
      ),
    ]);
  }
}
