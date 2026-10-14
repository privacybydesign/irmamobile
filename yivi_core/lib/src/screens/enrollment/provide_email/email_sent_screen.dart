import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_palette.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "../../../widgets/translated_text.dart";

class EmailSentScreen extends StatelessWidget {
  final String email;
  final VoidCallback onContinue;

  const EmailSentScreen({
    super.key,
    required this.email,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    // "**noreply@mail.yivi.app**" in the translation: bold the address.
    final fromText = FlutterI18n.translate(
      context,
      "enrollment.email.confirm.explanation_extra_markdown",
    );
    final fromParts = fromText.split("**");

    return Scaffold(
      backgroundColor: palette.background,
      key: const Key("email_sent_screen"),
      appBar: IrmaAppBar(
        titleTranslationKey: "enrollment.email.confirm.title",
        leading: null,
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: FlutterI18n.translate(context, "ui.next"),
        onPrimaryPressed: onContinue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
        child: Column(
          children: [
            const _MailPicture(),
            const SizedBox(height: 40),
            TranslatedText(
              "enrollment.email.confirm.header",
              isHeader: true,
              textAlign: TextAlign.center,
              style: palette
                  .display(24, weight: FontWeight.w700)
                  .copyWith(height: 32 / 24),
            ),
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: ShapeDecoration(
                color: palette.surface,
                shape: const StadiumBorder(),
                shadows: const [
                  BoxShadow(
                    color: Color(0x17000000),
                    blurRadius: 6,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  email,
                  textAlign: TextAlign.center,
                  style: palette.body(16, weight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text.rich(
              TextSpan(
                children: [
                  for (var i = 0; i < fromParts.length; i++)
                    TextSpan(
                      text: fromParts[i],
                      style: i.isOdd
                          ? const TextStyle(fontWeight: FontWeight.w700)
                          : null,
                    ),
                ],
              ),
              textAlign: TextAlign.center,
              style: palette.body(16).copyWith(height: 24 / 16),
            ),
            const SizedBox(height: 12),
            TranslatedText(
              "enrollment.email.confirm.explanation",
              textAlign: TextAlign.center,
              style: palette
                  .body(14)
                  .copyWith(height: 20 / 14, color: palette.secondaryText),
            ),
          ],
        ),
      ),
    );
  }
}

/// An envelope with a green tick in a white circle.
class _MailPicture extends StatelessWidget {
  const _MailPicture();

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return ExcludeSemantics(
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: palette.surface,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 6,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: SizedBox(
            width: 120,
            height: 96,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: palette.warningSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: palette.heading, width: 4),
                    ),
                    child: Icon(
                      Icons.drafts_outlined,
                      size: 56,
                      color: palette.heading,
                    ),
                  ),
                ),
                Positioned(
                  right: -14,
                  top: -14,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00973A),
                      shape: BoxShape.circle,
                      border: Border.all(color: palette.surface, width: 3),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
