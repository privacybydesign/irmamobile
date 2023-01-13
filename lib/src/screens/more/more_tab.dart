import 'package:flutter/material.dart';
import 'package:irmamobile/src/screens/more/widgets/grouped_links.dart';
import 'package:irmamobile/src/widgets/custom_button.dart';

import '../../theme/theme.dart';
import '../../widgets/irma_repository_provider.dart';
import '../../widgets/translated_text.dart';
import '../home/widgets/irma_nav_bar.dart';

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
          GroupedLinks(
            linkTiles: [
              LinkTile(
                labelTranslationKey: 'more_tab.settings',
                iconData: Icons.settings_outlined,
              ),
              LinkTile(
                labelTranslationKey: 'more_tab.faq',
                iconData: Icons.help_outline_rounded,
              )
            ],
          ),
          _buildHeaderText('help.about_irma'),
          GroupedLinks(
            linkTiles: [
              LinkTile(
                labelTranslationKey: 'more_tab.website',
                iconData: Icons.info_outline_rounded,
              ),
              LinkTile(
                labelTranslationKey: 'more_tab.contact',
                iconData: Icons.mail_outline,
              )
            ],
          ),
          _buildHeaderText('more_tab.slogan'),
          GroupedLinks(
            linkTiles: [
              LinkTile(
                labelTranslationKey: 'more_tab.share',
                iconData: Icons.info_outline_rounded,
              ),
              LinkTile(
                labelTranslationKey: 'more_tab.privacy_policy',
                iconData: Icons.mail_outline,
              )
            ],
          ),
          _buildHeaderText('more_tab.stay_informed'),
          GroupedLinks(
            linkTiles: [
              LinkTile(
                labelTranslationKey: 'more_tab.website',
                iconData: Icons.info_outline_rounded,
              ),
              LinkTile(
                labelTranslationKey: 'more_tab.contact',
                iconData: Icons.mail_outline,
              )
            ],
          ),
          Padding(
            padding: EdgeInsets.all(theme.defaultSpacing),
            child: CustomButton(
              style: CustomButtonStyle.filled,
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
