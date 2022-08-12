import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../theme/theme.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_markdown.dart';
import '../../widgets/translated_text.dart';
import '../home/widgets/links.dart';
import 'widgets/help_item.dart';
import 'widgets/help_item_carousel.dart';

class HelpScreen extends StatefulWidget {
  static const String routeName = '/help';

  @override
  _HelpScreenState createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final ScrollController _controller = ScrollController();

  Widget _buildHeader(
    IrmaThemeData theme,
    String translationKey, {
    TextStyle? style,
  }) =>
      TranslatedText(
        translationKey,
        style: style ?? theme.textTheme.bodyText1!.copyWith(color: theme.neutralDark),
      );

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Scaffold(
      appBar: const IrmaAppBar(
        titleTranslationKey: 'help.faq',
      ),
      body: ListView(
        controller: _controller,
        padding: EdgeInsets.symmetric(
          vertical: theme.smallSpacing,
          horizontal: theme.defaultSpacing,
        ),
        children: [
          _buildHeader(theme, 'help.about_irma'),
          SizedBox(height: theme.smallSpacing),
          HelpItem(
            headerTranslationKey: 'help.question_1',
            body: const TranslatedText('help.answer_1_markdown'),
            parentScrollController: _controller,
          ),
          SizedBox(height: theme.smallSpacing),
          HelpItem(
            headerTranslationKey: 'help.question_2',
            body: IrmaMarkdown(FlutterI18n.translate(context, 'help.answer_2')),
            parentScrollController: _controller,
          ),
          SizedBox(height: theme.smallSpacing),
          HelpItem(
            headerTranslationKey: 'help.question_3',
            body: const TranslatedText('help.answer_3_markdown'),
            parentScrollController: _controller,
          ),
          SizedBox(height: theme.defaultSpacing),
          _buildHeader(theme, 'help.login'),
          SizedBox(height: theme.smallSpacing),
          HelpItem(
            headerTranslationKey: 'help.question_4',
            body: HelpCarousel(items: [
              HelpCarouselItem('assets/help/mobile_login/website.svg', 'help.answer_4.step_1'),
              HelpCarouselItem('assets/help/mobile_login/app.svg', 'help.answer_4.step_2'),
              HelpCarouselItem('assets/help/mobile_login/success.svg', 'help.answer_4.step_3'),
              HelpCarouselItem('assets/help/mobile_login/website.svg', 'help.answer_4.step_4'),
            ]),
            parentScrollController: _controller,
          ),
          SizedBox(height: theme.smallSpacing),
          HelpItem(
            headerTranslationKey: 'help.question_5',
            body: HelpCarousel(items: [
              HelpCarouselItem('assets/help/computer_login/website.svg', 'help.answer_5.step_1'),
              HelpCarouselItem('assets/help/computer_login/app.svg', 'help.answer_5.step_2'),
              HelpCarouselItem('assets/help/computer_login/scan.svg', 'help.answer_5.step_3'),
              HelpCarouselItem('assets/help/computer_login/success.svg', 'help.answer_5.step_4'),
              HelpCarouselItem('assets/help/computer_login/website.svg', 'help.answer_5.step_5'),
            ]),
            parentScrollController: _controller,
          ),
          SizedBox(height: theme.defaultSpacing),
          _buildHeader(theme, 'help.device'),
          SizedBox(height: theme.smallSpacing),
          HelpItem(
            headerTranslationKey: 'help.question_6',
            body: const TranslatedText('help.answer_6_markdown'),
            parentScrollController: _controller,
          ),
          SizedBox(height: theme.smallSpacing),
          HelpItem(
            headerTranslationKey: 'help.question_7',
            body: const TranslatedText('help.answer_7'),
            parentScrollController: _controller,
          ),
          SizedBox(height: theme.defaultSpacing),
          _buildHeader(theme, 'help.storage_and_privacy'),
          SizedBox(height: theme.smallSpacing),
          HelpItem(
            headerTranslationKey: 'help.question_8',
            body: const TranslatedText('help.answer_8'),
            parentScrollController: _controller,
          ),
          SizedBox(height: theme.smallSpacing),
          HelpItem(
            headerTranslationKey: 'help.question_9',
            body: const TranslatedText('help.answer_9'),
            parentScrollController: _controller,
          ),
          SizedBox(height: theme.smallSpacing),
          HelpItem(
            headerTranslationKey: 'help.question_10',
            body: const TranslatedText('help.answer_10'),
            parentScrollController: _controller,
          ),
          SizedBox(height: theme.smallSpacing),
          HelpItem(
            headerTranslationKey: 'help.question_11',
            body: IrmaMarkdown(
              FlutterI18n.translate(context, 'help.answer_11'),
            ),
            parentScrollController: _controller,
          ),
          SizedBox(height: theme.defaultSpacing),
          _buildHeader(
            theme,
            'help.ask',
            style: theme.textTheme.headline3,
          ),
          SizedBox(height: theme.defaultSpacing),
          TranslatedText(
            'help.send',
            style: theme.textTheme.bodyText2,
          ),
          ContactLink(
            translationKey: 'help.email',
            textAlign: TextAlign.start,
            hasPadding: false,
            style: theme.textTheme.bodyText2!.copyWith(
              color: theme.themeData.colorScheme.secondary,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }
}
