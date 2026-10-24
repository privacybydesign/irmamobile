import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../../providers/preferences_provider.dart";
import "../../../../theme/theme.dart";
import "../../../../util/i18n.dart";
import "../../../../widgets/translated_text.dart";

/// Rewrites `[text](url)` to `text`. The accept label is markdown so it can
/// link to the terms, but a screen reader label has to be plain text. Deriving
/// it from the same translation keeps the two in sync per locale.
///
/// `[^)]*` stops at the first `)`, so a terms URL containing a parenthesis
/// would leak a stray character into the label. The caller avoids that by
/// translating without `translationParams`, leaving `{terms_url}` in place of
/// the URL — the link target is discarded here either way.
String _withoutMarkdownLinks(String markdown) => markdown.replaceAllMapped(
  RegExp(r"\[([^\]]*)\]\([^)]*\)"),
  (match) => match[1]!,
);

class TermsCheckBox extends ConsumerWidget {
  final bool isAccepted;
  final Function(bool) onToggleAccepted;

  const TermsCheckBox({
    required this.isAccepted,
    required this.onToggleAccepted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = IrmaTheme.of(context);

    final preferences = ref.watch(preferencesProvider);

    final termsUrl = (context.lang) == "nl"
        ? preferences.mostRecentTermsUrlNl
        : preferences.mostRecentTermsUrlEn;

    // No translationParams: the URL is only the link target and is stripped
    // out below, so keeping it out of the string means the label cannot depend
    // on what the URL contains.
    final acceptLabel = FlutterI18n.translate(
      context,
      "enrollment.terms_and_conditions.accept_markdown",
    );

    final semanticsLabel = _withoutMarkdownLinks(acceptLabel);

    final acceptText = TranslatedText(
      "enrollment.terms_and_conditions.accept_markdown",
      translationParams: {"terms_url": termsUrl},
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // The label lives in a sibling widget, so the checkbox itself has no
        // accessible name — merge one in, so a screen reader announces the
        // label together with the checkbox role and its checked state. The
        // markdown text keeps its own semantics, which is what makes the terms
        // link reachable.
        MergeSemantics(
          child: Semantics(
            label: semanticsLabel,
            child: Checkbox(
              key: const Key("accept_terms_checkbox"),
              value: isAccepted,
              activeColor: theme.primary,
              checkColor: theme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: BorderSide(color: theme.tertiary, width: 2),
              onChanged: (isAccepted) => onToggleAccepted(isAccepted ?? false),
            ),
          ),
        ),
        SizedBox(width: theme.smallSpacing),
        Flexible(child: acceptText),
      ],
    );
  }
}
