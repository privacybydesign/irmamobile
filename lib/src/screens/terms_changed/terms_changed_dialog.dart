import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/irma_repository_provider.dart';
import '../../providers/preferences_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_bottom_bar.dart';
import '../../widgets/irma_dialog.dart';
import '../../widgets/translated_text.dart';

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

    _subscription = stream.listen(
      (accepted) async {
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
      },
    );
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

    final isDutch = (FlutterI18n.currentLocale(context)?.languageCode ?? 'en') == 'nl';
    final termsUrl = isDutch ? prefs.mostRecentTermsUrlNl : prefs.mostRecentTermsUrlEn;

    final theme = IrmaTheme.of(context);

    return YiviDialog(
      key: const Key('terms_changed_dialog'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IrmaAppBar(
            titleTranslationKey: 'new_terms_and_conditions.title',
            leading: null,
          ),
          SingleChildScrollView(
            padding: EdgeInsets.all(theme.defaultSpacing),
            child: TranslatedText(
              'new_terms_and_conditions.explanation_markdown',
              translationParams: {'terms_url': termsUrl},
              markdownTextAlign: WrapAlignment.center,
            ),
          ),
          IrmaBottomBar(
            primaryButtonLabel: 'new_terms_and_conditions.accept',
            secondaryButtonLabel: 'new_terms_and_conditions.dismiss',
            onPrimaryPressed: () async {
              await prefs.markLatestTermsAsAccepted(true);
              if (context.mounted) {
                context.pop();
              }
            },
            onSecondaryPressed: () {
              context.pop();
            },
          ),
        ],
      ),
    );

    // return ;
  }
}
