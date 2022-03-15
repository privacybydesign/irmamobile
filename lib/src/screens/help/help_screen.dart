import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/screens/help/widgets/help_item.dart';
import 'package:irmamobile/src/screens/help/widgets/help_item_carousel.dart';
import 'package:irmamobile/src/screens/home/widgets/links.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/irma_markdown.dart';
import 'package:irmamobile/src/widgets/translated_text.dart';

class HelpScreen extends StatefulWidget {
  static const String routeName = '/help';

  @override
  _HelpScreenState createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _scrollviewKey = GlobalKey();
  final ScrollController _controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: const IrmaAppBar(title: TranslatedText('help.title')),
        body: Container(
          padding: EdgeInsets.symmetric(
              horizontal: IrmaTheme.of(context).largeSpacing, vertical: IrmaTheme.of(context).defaultSpacing),
          child: ListView(key: _scrollviewKey, controller: _controller, children: [
            TranslatedText(
              'help.faq',
              style: IrmaTheme.of(context).textTheme.headline3,
            ),
            SizedBox(height: IrmaTheme.of(context).defaultSpacing),
            TranslatedText(
              'help.about_irma',
              style: IrmaTheme.of(context).textTheme.bodyText2,
            ),
            SizedBox(height: IrmaTheme.of(context).smallSpacing),
            HelpItem(
              headerTranslationKey: 'help.question_1',
              body: const TranslatedText('help.answer_1'),
              parentKey: _scrollviewKey,
              parentScrollController: _controller,
            ),
            SizedBox(height: IrmaTheme.of(context).smallSpacing),
            HelpItem(
              headerTranslationKey: 'help.question_9',
              body: IrmaMarkdown(FlutterI18n.translate(context, 'help.answer_9')),
              parentKey: _scrollviewKey,
              parentScrollController: _controller,
            ),
            SizedBox(height: IrmaTheme.of(context).smallSpacing),
            HelpItem(
              headerTranslationKey: 'help.question_10',
              body: const TranslatedText('help.answer_10'),
              parentKey: _scrollviewKey,
              parentScrollController: _controller,
            ),
            SizedBox(height: IrmaTheme.of(context).defaultSpacing),
            TranslatedText(
              'help.login',
              style: IrmaTheme.of(context).textTheme.bodyText2,
            ),
            SizedBox(height: IrmaTheme.of(context).smallSpacing),
            HelpItem(
              headerTranslationKey: 'help.question_7',
              body: HelpCarousel(items: [
                HelpCarouselItem('assets/help/q1_step_1.svg', 'help.answer_7.step_1'),
                HelpCarouselItem('assets/help/q1_step_2.svg', 'help.answer_7.step_2'),
                HelpCarouselItem('assets/help/q1_step_3.svg', 'help.answer_7.step_3'),
                HelpCarouselItem('assets/help/q1_step_4.svg', 'help.answer_7.step_4'),
              ]),
              parentKey: _scrollviewKey,
              parentScrollController: _controller,
            ),
            SizedBox(height: IrmaTheme.of(context).smallSpacing),
            HelpItem(
              headerTranslationKey: 'help.question_8',
              body: HelpCarousel(items: [
                HelpCarouselItem('assets/help/q2_step_1.svg', 'help.answer_8.step_1'),
                HelpCarouselItem('assets/help/q2_step_2.svg', 'help.answer_8.step_2'),
                HelpCarouselItem('assets/help/q2_step_3.svg', 'help.answer_8.step_3'),
                HelpCarouselItem('assets/help/q2_step_3.svg', 'help.answer_8.step_4'),
                HelpCarouselItem('assets/help/q2_step_3.svg', 'help.answer_8.step_5'),
              ]),
              parentKey: _scrollviewKey,
              parentScrollController: _controller,
            ),
            SizedBox(height: IrmaTheme.of(context).defaultSpacing),
            TranslatedText(
              'help.device',
              style: IrmaTheme.of(context).textTheme.bodyText2,
            ),
            SizedBox(height: IrmaTheme.of(context).smallSpacing),
            HelpItem(
              headerTranslationKey: 'help.question_2',
              body: const TranslatedText('help.answer_2'),
              parentKey: _scrollviewKey,
              parentScrollController: _controller,
            ),
            SizedBox(height: IrmaTheme.of(context).smallSpacing),
            HelpItem(
              headerTranslationKey: 'help.question_6',
              body: const TranslatedText('help.answer_6'),
              parentKey: _scrollviewKey,
              parentScrollController: _controller,
            ),
            SizedBox(height: IrmaTheme.of(context).defaultSpacing),
            TranslatedText(
              'help.storage_and_privacy',
              style: IrmaTheme.of(context).textTheme.bodyText2,
            ),
            SizedBox(height: IrmaTheme.of(context).smallSpacing),
            HelpItem(
              headerTranslationKey: 'help.question_4',
              body: const TranslatedText('help.answer_4'),
              parentKey: _scrollviewKey,
              parentScrollController: _controller,
            ),
            SizedBox(height: IrmaTheme.of(context).smallSpacing),
            HelpItem(
              headerTranslationKey: 'help.question_3',
              body: const TranslatedText('help.answer_3'),
              parentKey: _scrollviewKey,
              parentScrollController: _controller,
            ),
            SizedBox(height: IrmaTheme.of(context).smallSpacing),
            HelpItem(
              headerTranslationKey: 'help.question_5',
              body: const TranslatedText('help.answer_5'),
              parentKey: _scrollviewKey,
              parentScrollController: _controller,
            ),
            SizedBox(height: IrmaTheme.of(context).smallSpacing),
            HelpItem(
              headerTranslationKey: 'help.question_11',
              body: IrmaMarkdown(FlutterI18n.translate(context, 'help.answer_11')),
              parentKey: _scrollviewKey,
              parentScrollController: _controller,
            ),
            SizedBox(height: IrmaTheme.of(context).defaultSpacing),
            TranslatedText(
              'help.ask',
              style: IrmaTheme.of(context).textTheme.headline3,
            ),
            SizedBox(height: IrmaTheme.of(context).defaultSpacing),
            TranslatedText(
              'help.send',
              style: IrmaTheme.of(context).textTheme.bodyText2,
            ),
            SizedBox(height: IrmaTheme.of(context).defaultSpacing),
            ContactLink(
              translationKey: 'help.email',
              textAlign: TextAlign.center,
              style: IrmaTheme.of(context)
                  .textTheme
                  .bodyText2!
                  .copyWith(color: IrmaTheme.of(context).themeData.primaryColor, decoration: TextDecoration.underline),
            ),
          ]),
        ));
  }
}
