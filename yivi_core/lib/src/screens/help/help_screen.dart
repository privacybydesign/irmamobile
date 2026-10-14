import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../package_name.dart";
import "../../theme/yivi_palette.dart";
import "../../widgets/glass/glass_group.dart";
import "../../widgets/glass/pill_buttons.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/irma_markdown.dart";
import "../../widgets/link.dart";
import "../../widgets/translated_text.dart";
import "widgets/help_item.dart";
import "widgets/help_item_carousel.dart";

class HelpScreen extends StatefulWidget {
  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final ScrollController _controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: IrmaAppBar(titleTranslationKey: "help.faq"),
      body: SingleChildScrollView(
        controller: _controller,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassGroup(
                header: FlutterI18n.translate(context, "help.about_irma"),
                children: [
                  HelpItem(
                    headerTranslationKey: "help.question_1",
                    body: const TranslatedText("help.answer_1_markdown"),
                    parentScrollController: _controller,
                  ),
                  HelpItem(
                    headerTranslationKey: "help.question_2",
                    body: IrmaMarkdown(
                      FlutterI18n.translate(context, "help.answer_2"),
                    ),
                    parentScrollController: _controller,
                  ),
                  HelpItem(
                    headerTranslationKey: "help.question_3",
                    body: const TranslatedText("help.answer_3_markdown"),
                    parentScrollController: _controller,
                  ),
                ],
              ),
              GlassGroup(
                header: FlutterI18n.translate(context, "help.login"),
                children: [
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
                ],
              ),
              GlassGroup(
                header: FlutterI18n.translate(context, "help.device"),
                children: [
                  HelpItem(
                    headerTranslationKey: "help.question_6",
                    body: const TranslatedText("help.answer_6_markdown"),
                    parentScrollController: _controller,
                  ),
                  HelpItem(
                    headerTranslationKey: "help.question_7",
                    body: const TranslatedText("help.answer_7"),
                    parentScrollController: _controller,
                  ),
                ],
              ),
              GlassGroup(
                header: FlutterI18n.translate(
                  context,
                  "help.security_and_privacy",
                ),
                children: [
                  HelpItem(
                    headerTranslationKey: "help.question_8",
                    body: const TranslatedText("help.answer_8"),
                    parentScrollController: _controller,
                  ),
                  HelpItem(
                    headerTranslationKey: "help.question_9",
                    body: const TranslatedText("help.answer_9"),
                    parentScrollController: _controller,
                  ),
                  HelpItem(
                    headerTranslationKey: "help.question_10",
                    body: const TranslatedText("help.answer_10"),
                    parentScrollController: _controller,
                  ),
                  HelpItem(
                    headerTranslationKey: "help.question_11",
                    body: IrmaMarkdown(
                      FlutterI18n.translate(context, "help.answer_11"),
                    ),
                    parentScrollController: _controller,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const _AskAQuestion(),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Ask a question": a card with a mail tile, the explanation and a button
/// that opens a new e-mail to support.
class _AskAQuestion extends StatelessWidget {
  const _AskAQuestion();

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return GlassGroup(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Row(
                spacing: 12,
                children: [
                  ExcludeSemantics(
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: palette.warningSurface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.mail_outline_rounded,
                        color: palette.warningText,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TranslatedText(
                      "help.ask",
                      isHeader: true,
                      style: palette.display(18),
                    ),
                  ),
                ],
              ),
              TranslatedText(
                "help.send",
                style: palette
                    .body(15)
                    .copyWith(height: 22 / 15, color: palette.heading),
              ),
              PillButton(
                key: const Key("help_send_email"),
                label: FlutterI18n.translate(context, "help.email"),
                onPressed: () => openSupportMail(context),
              ),
              TranslatedText(
                "help.contact",
                textAlign: TextAlign.center,
                style: palette.body(13).copyWith(color: palette.secondaryText),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
