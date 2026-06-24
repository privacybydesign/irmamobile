import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "../../../package_name.dart";

import "../../theme/theme.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/irma_markdown.dart";
import "../../widgets/link.dart";
import "../../widgets/section_header.dart";
import "../../widgets/translated_text.dart";
import "widgets/help_item.dart";
import "widgets/help_item_carousel.dart";

class HelpScreen extends StatefulWidget {
  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final ScrollController _controller = ScrollController();

  Widget _buildHeader(String translationKey) => SectionHeader(translationKey);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surfaceContainerHigh,
      appBar: IrmaAppBar(titleTranslationKey: "help.faq"),
      body: SingleChildScrollView(
        controller: _controller,
        padding: EdgeInsets.all(context.yivi.spacing.base),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader("help.about_irma"),
              SizedBox(height: context.yivi.spacing.small),
              HelpItem(
                headerTranslationKey: "help.question_1",
                body: const TranslatedText("help.answer_1_markdown"),
                parentScrollController: _controller,
              ),
              SizedBox(height: context.yivi.spacing.small),
              HelpItem(
                headerTranslationKey: "help.question_2",
                body: IrmaMarkdown(
                  FlutterI18n.translate(context, "help.answer_2"),
                ),
                parentScrollController: _controller,
              ),
              SizedBox(height: context.yivi.spacing.small),
              HelpItem(
                headerTranslationKey: "help.question_3",
                body: const TranslatedText("help.answer_3_markdown"),
                parentScrollController: _controller,
              ),
              SizedBox(height: context.yivi.spacing.large),
              _buildHeader("help.login"),
              SizedBox(height: context.yivi.spacing.small),
              HelpItem(
                headerTranslationKey: "help.question_4",
                body: HelpCarousel(
                  items: [
                    HelpCarouselItem(
                      yiviAsset("help/mobile_login/app.svg"),
                      "help.answer_4.step_1",
                    ),
                    HelpCarouselItem(
                      yiviAsset("help/mobile_login/pin.svg"),
                      "help.answer_4.step_2",
                    ),
                    HelpCarouselItem(
                      yiviAsset("help/mobile_login/disclosure.svg"),
                      "help.answer_4.step_3",
                    ),
                    HelpCarouselItem(
                      yiviAsset("help/mobile_login/success.svg"),
                      "help.answer_4.step_4",
                    ),
                  ],
                ),
                parentScrollController: _controller,
              ),
              SizedBox(height: context.yivi.spacing.small),
              HelpItem(
                headerTranslationKey: "help.question_5",
                body: HelpCarousel(
                  items: [
                    HelpCarouselItem(
                      yiviAsset("help/computer_login/app.svg"),
                      "help.answer_5.step_1",
                    ),
                    HelpCarouselItem(
                      yiviAsset("help/computer_login/pin.svg"),
                      "help.answer_5.step_2",
                    ),
                    HelpCarouselItem(
                      yiviAsset("help/computer_login/scan.svg"),
                      "help.answer_5.step_3",
                    ),
                    HelpCarouselItem(
                      yiviAsset("help/computer_login/disclosure.svg"),
                      "help.answer_5.step_4",
                    ),
                    HelpCarouselItem(
                      yiviAsset("help/computer_login/success.svg"),
                      "help.answer_5.step_5",
                    ),
                  ],
                ),
                parentScrollController: _controller,
              ),
              SizedBox(height: context.yivi.spacing.large),
              _buildHeader("help.device"),
              SizedBox(height: context.yivi.spacing.small),
              HelpItem(
                headerTranslationKey: "help.question_6",
                body: const TranslatedText("help.answer_6_markdown"),
                parentScrollController: _controller,
              ),
              SizedBox(height: context.yivi.spacing.small),
              HelpItem(
                headerTranslationKey: "help.question_7",
                body: const TranslatedText("help.answer_7"),
                parentScrollController: _controller,
              ),
              SizedBox(height: context.yivi.spacing.large),
              _buildHeader("help.security_and_privacy"),
              SizedBox(height: context.yivi.spacing.small),
              HelpItem(
                headerTranslationKey: "help.question_8",
                body: const TranslatedText("help.answer_8"),
                parentScrollController: _controller,
              ),
              SizedBox(height: context.yivi.spacing.small),
              HelpItem(
                headerTranslationKey: "help.question_9",
                body: const TranslatedText("help.answer_9"),
                parentScrollController: _controller,
              ),
              SizedBox(height: context.yivi.spacing.small),
              HelpItem(
                headerTranslationKey: "help.question_10",
                body: const TranslatedText("help.answer_10"),
                parentScrollController: _controller,
              ),
              SizedBox(height: context.yivi.spacing.small),
              HelpItem(
                headerTranslationKey: "help.question_11",
                body: IrmaMarkdown(
                  FlutterI18n.translate(context, "help.answer_11"),
                ),
                parentScrollController: _controller,
              ),
              SizedBox(height: context.yivi.spacing.large),
              _buildHeader("help.ask"),
              SizedBox(height: context.yivi.spacing.base),
              TranslatedText("help.send", style: context.text.bodyMedium),
              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: context.yivi.spacing.small,
                ),
                child: const ContactLink(translationKey: "help.email"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
