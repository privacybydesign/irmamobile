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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _scrollViewKey = GlobalKey();
  final ScrollController _controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: const IrmaAppBar(
        titleTranslationKey: 'help.title',
      ),
      body: ListView(
        key: _scrollViewKey,
        controller: _controller,
        padding: EdgeInsets.symmetric(
          vertical: theme.smallSpacing,
          horizontal: theme.defaultSpacing,
        ),
        children: [
          TranslatedText(
            'help.faq',
            style: theme.textTheme.headline3,
          ),
          SizedBox(height: theme.defaultSpacing),
          TranslatedText(
            'help.about_irma',
            style: theme.textTheme.bodyText2,
          ),
          SizedBox(height: theme.smallSpacing),
          HelpItem(
            headerTranslationKey: 'help.question_1',
            body: const TranslatedText('help.answer_1'),
            parentKey: _scrollViewKey,
            parentScrollController: _controller,
          ),
          SizedBox(height: theme.smallSpacing),
          HelpItem(
            headerTranslationKey: 'help.question_2',
            body: IrmaMarkdown(FlutterI18n.translate(context, 'help.answer_2')),
            parentKey: _scrollViewKey,
            parentScrollController: _controller,
          ),
          SizedBox(height: theme.smallSpacing),
          HelpItem(
            headerTranslationKey: 'help.question_3',
            body: const TranslatedText('help.answer_3'),
            parentKey: _scrollViewKey,
            parentScrollController: _controller,
          ),
          SizedBox(height: theme.defaultSpacing),
          TranslatedText(
            'help.login',
            style: theme.textTheme.bodyText2,
          ),
          SizedBox(height: theme.smallSpacing),
          HelpItem(
            headerTranslationKey: 'help.question_4',
            body: HelpCarousel(items: [
              HelpCarouselItem('assets/help/q4_step_1.svg', 'help.answer_4.step_1'),
              HelpCarouselItem('assets/help/q4_step_2.svg', 'help.answer_4.step_2'),
              HelpCarouselItem('assets/help/q4_step_3.svg', 'help.answer_4.step_3'),
              HelpCarouselItem('assets/help/q4_step_4.svg', 'help.answer_4.step_4'),
            ]),
            parentKey: _scrollViewKey,
            parentScrollController: _controller,
          ),
          SizedBox(height: theme.smallSpacing),
          HelpItem(
            headerTranslationKey: 'help.question_5',
            body: HelpCarousel(items: [
              HelpCarouselItem('assets/help/q5_step_1.svg', 'help.answer_5.step_1'),
              HelpCarouselItem('assets/help/q5_step_2.svg', 'help.answer_5.step_2'),
              HelpCarouselItem('assets/help/q5_step_3.svg', 'help.answer_5.step_3'),
              HelpCarouselItem('assets/help/q5_step_4.svg', 'help.answer_5.step_4'),
              HelpCarouselItem('assets/help/q5_step_5.svg', 'help.answer_5.step_5'),
            ]),
            parentKey: _scrollViewKey,
            parentScrollController: _controller,
          ),
          SizedBox(height: theme.defaultSpacing),
          TranslatedText(
            'help.device',
            style: theme.textTheme.bodyText2,
          ),
          SizedBox(height: theme.smallSpacing),
          HelpItem(
            headerTranslationKey: 'help.question_6',
            body: const TranslatedText('help.answer_6'),
            parentKey: _scrollViewKey,
            parentScrollController: _controller,
          ),
          SizedBox(height: theme.smallSpacing),
          HelpItem(
            headerTranslationKey: 'help.question_7',
            body: const TranslatedText('help.answer_7'),
            parentKey: _scrollViewKey,
            parentScrollController: _controller,
          ),
          SizedBox(height: theme.defaultSpacing),
          TranslatedText(
            'help.storage_and_privacy',
            style: theme.textTheme.bodyText2,
          ),
          SizedBox(height: theme.smallSpacing),
          HelpItem(
            headerTranslationKey: 'help.question_8',
            body: const TranslatedText('help.answer_8'),
            parentKey: _scrollViewKey,
            parentScrollController: _controller,
          ),
          SizedBox(height: theme.smallSpacing),
          HelpItem(
            headerTranslationKey: 'help.question_9',
            body: const TranslatedText('help.answer_9'),
            parentKey: _scrollViewKey,
            parentScrollController: _controller,
          ),
          SizedBox(height: theme.smallSpacing),
          HelpItem(
            headerTranslationKey: 'help.question_10',
            body: const TranslatedText('help.answer_10'),
            parentKey: _scrollViewKey,
            parentScrollController: _controller,
          ),
          SizedBox(height: theme.smallSpacing),
          HelpItem(
            headerTranslationKey: 'help.question_11',
            body: IrmaMarkdown(FlutterI18n.translate(context, 'help.answer_11')),
            parentKey: _scrollViewKey,
            parentScrollController: _controller,
          ),
          SizedBox(height: theme.defaultSpacing),
          TranslatedText(
            'help.ask',
            style: theme.textTheme.headline3,
          ),
          SizedBox(height: theme.defaultSpacing),
          TranslatedText(
            'help.send',
            style: theme.textTheme.bodyText2,
          ),
          SizedBox(height: theme.defaultSpacing),
          ContactLink(
            translationKey: 'help.email',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyText2!
                .copyWith(color: theme.themeData.colorScheme.secondary, decoration: TextDecoration.underline),
          ),
        ],
      ),
    );
  }
}
