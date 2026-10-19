import "dart:async";

import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../providers/preferences_provider.dart";
import "../../widgets/glass/glass_dialog.dart";
import "../../widgets/glass/pill_buttons.dart";
import "../../widgets/translated_text.dart";

class TermsChangedListener extends ConsumerStatefulWidget {
  const TermsChangedListener({required this.child});

  final Widget child;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _TermsChangedListenerState();
  }
}

class _TermsChangedListenerState extends ConsumerState<TermsChangedListener> {
  StreamSubscription<bool>? _subscription;
  bool _dialogActive = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _subscription?.cancel();

    final preferences = ref.read(preferencesProvider);
    final stream = preferences.hasAcceptedLatestTerms();

    _subscription = stream.listen((accepted) async {
      if (!accepted && mounted && !_dialogActive) {
        // making sure the dialog is only showing once, not in a stack...
        _dialogActive = true;
        await showDialog(
          context: context,
          builder: (context) {
            return TermsChangedDialog();
          },
        );
        _dialogActive = false;
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _subscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// ==================================================================================

class TermsChangedDialog extends ConsumerStatefulWidget {
  const TermsChangedDialog({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _TermsChangedDialogState();
  }
}

class _TermsChangedDialogState extends ConsumerState<TermsChangedDialog> {
  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(preferencesProvider);

    final isDutch =
        (FlutterI18n.currentLocale(context)?.languageCode ?? "en") == "nl";
    final termsUrl = isDutch
        ? prefs.mostRecentTermsUrlNl
        : prefs.mostRecentTermsUrlEn;

    // `Navigator.of` (not GoRouter's `context.pop`) because the dialog
    // may be hosted in a local Navigator (e.g. `LockGate`'s overlay) that
    // sits above the GoRouter scope.
    return GlassDialog(
      key: const Key("terms_changed_dialog"),
      title: FlutterI18n.translate(context, "new_terms_and_conditions.title"),
      body: TranslatedText(
        "new_terms_and_conditions.explanation_markdown",
        translationParams: {"terms_url": termsUrl},
      ),
      actions: [
        // The keys of the bottom bar this dialog used to have.
        FancyPillButton(
          key: const Key("bottom_bar_primary"),
          label: FlutterI18n.translate(
            context,
            "new_terms_and_conditions.accept",
          ),
          size: PillSize.regular,
          onPressed: () async {
            await prefs.markLatestTermsAsAccepted(true);
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
        PillButton(
          key: const Key("bottom_bar_secondary"),
          label: FlutterI18n.translate(
            context,
            "new_terms_and_conditions.dismiss",
          ),
          style: PillStyle.text,
          size: PillSize.regular,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
