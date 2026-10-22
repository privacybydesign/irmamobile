import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_corners.dart";
import "../../../theme/yivi_palette.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "../../../widgets/translated_text.dart";
import "widgets/email_input_field.dart";
import "widgets/skip_email_confirmation_dialog.dart";

class ProvideEmailScreen extends StatefulWidget {
  final String? email;
  final Function(String) onEmailProvided;
  final VoidCallback onEmailSkipped;
  final VoidCallback onPrevious;

  const ProvideEmailScreen({
    this.email,
    required this.onEmailProvided,
    required this.onEmailSkipped,
    required this.onPrevious,
  });

  @override
  State<ProvideEmailScreen> createState() => _ProvideEmailScreenState();
}

class _ProvideEmailScreenState extends State<ProvideEmailScreen> {
  final _emailController = TextEditingController();

  @override
  void initState() {
    _emailController.text = widget.email ?? "";
    _emailController.addListener(_rebuild);
    super.initState();
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _emailController.removeListener(_rebuild);
    _emailController.dispose();
    super.dispose();
  }

  bool get _valid => EmailInputField.isValid(_emailController.text);

  void _onContinuePressed() {
    if (_valid) widget.onEmailProvided(_emailController.text);
  }

  void _onSkipPressed() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => SkipEmailConfirmationDialog(),
        ) ??
        false;
    if (confirmed) widget.onEmailSkipped();
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: palette.background,
      appBar: IrmaAppBar(
        titleTranslationKey: "enrollment.email.provide.title",
        leading: YiviBackButton(onTap: widget.onPrevious),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ExcludeSemantics(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: palette.warningSurface,
                      borderRadius: BorderRadius.circular(YiviCorners.iconTile),
                    ),
                    child: Icon(
                      Icons.mail_outline_rounded,
                      size: 48,
                      color: palette.warningText,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TranslatedText(
                "enrollment.email.provide.header",
                isHeader: true,
                textAlign: TextAlign.center,
                style: palette
                    .display(24, weight: FontWeight.w700)
                    .copyWith(height: 32 / 24),
              ),
              const SizedBox(height: 8),
              TranslatedText(
                "enrollment.email.provide.explanation",
                textAlign: TextAlign.center,
                style: palette.body(16).copyWith(height: 24 / 16),
              ),
              const SizedBox(height: 32),
              EmailInputField(
                controller: _emailController,
                onSubmitted: _onContinuePressed,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        alignment: IrmaBottomBarAlignment.vertical,
        primaryButtonLabel: "ui.next",
        onPrimaryPressed: _valid ? _onContinuePressed : null,
        secondaryButtonLabel: "ui.skip",
        onSecondaryPressed: _onSkipPressed,
      ),
    );
  }
}
