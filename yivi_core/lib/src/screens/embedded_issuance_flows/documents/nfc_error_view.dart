part of "nfc_reading_screen.dart";

Future _showLogsDialog(
  BuildContext context, {
  required String logs,
  String? sensitiveLogs,
}) async {
  return showDialog(
    context: context,
    builder: (context) {
      return NfcErrorDialog(logs: logs, sensitiveLogs: sensitiveLogs);
    },
  );
}

class _TitleAndBody extends StatelessWidget {
  const _TitleAndBody({
    required this.titleKey,
    required this.bodyKey,
    this.trailing,
  });

  final String titleKey;
  final String bodyKey;

  /// Under the body (the error's "Show error" link).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final isPortrait = MediaQuery.orientationOf(context) == .portrait;
    return Column(
      crossAxisAlignment: isPortrait ? .center : .start,
      mainAxisAlignment: .center,
      mainAxisSize: .min,
      children: [
        _OrientationAwareTranslatedText(titleKey, style: theme.bodyHeading),
        SizedBox(height: theme.defaultSpacing),
        _OrientationAwareTranslatedText(bodyKey),
        if (trailing case final trailing?) ...[
          SizedBox(height: theme.defaultSpacing),
          trailing,
        ],
      ],
    );
  }
}

class _NfcScaffold extends StatelessWidget {
  const _NfcScaffold({
    required this.titleTranslationKey,
    required this.instruction,
    required this.illustration,
    required this.bottomNavigationBar,
  });

  final String titleTranslationKey;
  final Widget instruction;
  final Widget illustration;
  final Widget bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    // In a sheet held sideways: what went wrong and the button at the left,
    // the illustration on a card at the right.
    final footer = bottomNavigationBar;
    if (documentStepSplit(context)) {
      return DocumentStepScaffold.split(
        SheetSplit(
          endFills: true,
          start: [instruction],
          end: SheetPictureCard(
            child: SizedBox(width: 280, height: 240, child: illustration),
          ),
          actions: footer is DocumentFlowFooter
              ? DocumentFlowFooter.sheetActions(context, footer.buttons)
              : null,
        ),
      );
    }
    return DocumentStepScaffold(
      titleKey: titleTranslationKey,
      body: SafeArea(
        child: Center(
          child: OrientationBuilder(
            builder: (context, orientation) {
              if (orientation == .landscape) {
                return Row(
                  mainAxisAlignment: .spaceEvenly,
                  crossAxisAlignment: .center,
                  children: [
                    Flexible(child: instruction),
                    Flexible(child: illustration),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: .center,
                mainAxisAlignment: .center,
                mainAxisSize: .max,
                children: [
                  Flexible(child: illustration),
                  SizedBox(height: theme.largeSpacing),
                  Flexible(child: instruction),
                ],
              );
            },
          ),
        ),
      ),
      bottomBar: bottomNavigationBar,
    );
  }
}

class _OrientationAwareTranslatedText extends StatelessWidget {
  const _OrientationAwareTranslatedText(this.translationKey, {this.style});

  final String translationKey;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final isPortrait = MediaQuery.orientationOf(context) == .portrait;
    final theme = IrmaTheme.of(context);

    return Padding(
      padding: isPortrait
          ? .symmetric(horizontal: theme.defaultSpacing)
          : .zero,
      child: TranslatedText(
        translationKey,
        textAlign: isPortrait ? .center : .start,
        style: style,
      ),
    );
  }
}

class _UiState {
  final String tipKey;
  final String stateKey;

  _UiState({required this.tipKey, required this.stateKey});
}
