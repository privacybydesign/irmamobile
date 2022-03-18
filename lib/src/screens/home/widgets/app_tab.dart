import 'package:flutter/material.dart';
import 'package:irmamobile/src/screens/home/widgets/links.dart';
import 'package:irmamobile/src/screens/home/widgets/version_button.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/translated_text.dart';

class AppTab extends StatelessWidget {
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
        title: TranslatedText('home.nav_bar.app'),
        noLeading: true,
      ),
      Expanded(
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).defaultSpacing),
          shrinkWrap: true,
          children: [
            _buildHeaderText('app_tab.app_management'),
            const InternalLink(
                iconData: Icons.settings_outlined, translationKey: 'app_tab.settings', routeName: '/settings'),
            const InternalLink(
                iconData: Icons.contact_support_outlined, translationKey: 'help.faq', routeName: '/help'),
            _buildHeaderText('help.about_irma'),
            const ExternalLink(
                iconData: Icons.info_outline, translationKey: 'app_tab.website', linkKey: 'app_tab.irma_website_link'),
            const ContactLink(iconData: Icons.mail_outline, translationKey: 'app_tab.contact'),
            _buildHeaderText('app_tab.slogan'),
            const ShareLink(
              iconData: Icons.share_outlined,
              translationKey: 'app_tab.share',
              shareTextKey: 'app_tab.share_text',
            ),
            const ExternalLink(
                iconData: Icons.description_outlined,
                translationKey: 'app_tab.privacy_policy',
                linkKey: 'enrollment.introduction.screen3.privacy.url'),
            _buildHeaderText('app_tab.stay_informed'),
            const ExternalLink(
                iconData: Icons.groups_outlined, translationKey: 'app_tab.meetups', linkKey: 'app_tab.meetups_link'),
            const ExternalLink(
                iconData: IrmaIcons.twitter, translationKey: 'app_tab.twitter', linkKey: 'app_tab.twitter_link'),
            const ExternalLink(
                iconData: IrmaIcons.github, translationKey: 'app_tab.github', linkKey: 'app_tab.github_link'),
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
