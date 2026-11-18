import "package:material_ui/material_ui.dart";

import "../../../package_name.dart";
import "../../theme/yivi_palette.dart";
import "../../theme/yivi_space.dart";
import "../../util/i18n.dart";
import "../../widgets/buttons/link.dart";
import "../../widgets/buttons/pill_buttons.dart";
import "../../widgets/surfaces/icon_square.dart";
import "../../widgets/surfaces/inset_group.dart";
import "../../widgets/text/markdown.dart";
import "../../widgets/text/translated_text.dart";
import "../more/widgets/more_subpage.dart";
import "widgets/help_item.dart";
import "widgets/help_item_carousel.dart";

class HelpScreen extends StatefulWidget {
  /// Shown in the More tab's detail pane: no app bar, a title on the page.
  final bool embedded;

  const HelpScreen({super.key, this.embedded = false});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MoreSubpage(
      embedded: widget.embedded,
      titleKey: "help.faq",
      top: 0,
      controller: _controller,
      children: [
        InsetGroup(
          header: context.tr("help.about_irma"),
          children: [
            HelpItem(
              headerTranslationKey: "help.question_1",
              body: const TranslatedText("help.answer_1_markdown"),
            ),
            HelpItem(
              headerTranslationKey: "help.question_2",
              body: YiviMarkdown(context.tr("help.answer_2")),
            ),
            HelpItem(
              headerTranslationKey: "help.question_3",
              body: const TranslatedText("help.answer_3_markdown"),
            ),
          ],
        ),
        InsetGroup(
          header: context.tr("help.login"),
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
            ),
          ],
        ),
        InsetGroup(
          header: context.tr("help.device"),
          children: [
            HelpItem(
              headerTranslationKey: "help.question_6",
              body: const TranslatedText("help.answer_6_markdown"),
            ),
            HelpItem(
              headerTranslationKey: "help.question_7",
              body: const TranslatedText("help.answer_7"),
            ),
          ],
        ),
        InsetGroup(
          header: context.tr("help.security_and_privacy"),
          children: [
            HelpItem(
              headerTranslationKey: "help.question_8",
              body: const TranslatedText("help.answer_8"),
            ),
            HelpItem(
              headerTranslationKey: "help.question_9",
              body: const TranslatedText("help.answer_9"),
            ),
            HelpItem(
              headerTranslationKey: "help.question_10",
              body: const TranslatedText("help.answer_10"),
            ),
            HelpItem(
              headerTranslationKey: "help.question_11",
              body: YiviMarkdown(context.tr("help.answer_11")),
            ),
          ],
        ),
        const SizedBox(height: YiviSpace.x24),
        const _AskAQuestion(),
      ],
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
    return InsetGroup(
      children: [
        Padding(
          padding: const EdgeInsets.all(YiviSpace.x16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: YiviSpace.x12,
            children: [
              Row(
                spacing: YiviSpace.x12,
                children: [
                  ExcludeSemantics(
                    child: IconSquare(
                      icon: Icons.mail_outline_rounded,
                      fill: palette.warningSurface,
                      ink: palette.warningText,
                      size: 44,
                      iconSize: null,
                      radius: 14,
                    ),
                  ),
                  Expanded(
                    child: TranslatedText(
                      "help.ask",
                      isHeader: true,
                      style: palette.titleSmall,
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
                label: context.tr("help.email"),
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
