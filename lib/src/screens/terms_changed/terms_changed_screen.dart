import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:go_router/go_router.dart';

import '../../data/irma_preferences.dart';
import '../../models/clear_all_data_event.dart';
import '../../providers/irma_repository_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_bottom_bar.dart';
import '../../widgets/irma_confirmation_dialog.dart';
import '../../widgets/irma_dialog.dart';
import '../../widgets/translated_text.dart';

class TermsChangedListener extends StatefulWidget {
  const TermsChangedListener({required this.child});

  final Widget child;

  @override
  State<TermsChangedListener> createState() => _TermsChangedListenerState();
}

class _TermsChangedListenerState extends State<TermsChangedListener> {
  StreamSubscription<bool>? _subscription;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _subscription?.cancel();

    final stream = IrmaRepositoryProvider.of(context).preferences.hasAcceptedLatestTerms();

    _subscription = stream.listen(
      (accepted) {
        if (!accepted && mounted) {
          showDialog(
            context: context,
            builder: (context) {
              return TermsChangedDialog();
            },
          );
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

class TermsChangedDialog extends StatefulWidget {
  const TermsChangedDialog({super.key});

  @override
  State<TermsChangedDialog> createState() => _TermsChangedDialogState();
}

class _TermsChangedDialogState extends State<TermsChangedDialog> {
  bool viewedNewTerms = false;

  @override
  Widget build(BuildContext context) {
    final prefs = IrmaRepositoryProvider.of(context).preferences;

    final termsUrl = (FlutterI18n.currentLocale(context)?.languageCode ?? 'en') == 'nl'
        ? IrmaPreferences.mostRecentTermsUrlNl
        : IrmaPreferences.mostRecentTermsUrlEn;

    final theme = IrmaTheme.of(context);

    return YiviDialog(
      maxHeight: 500,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IrmaAppBar(
            titleTranslationKey: 'new_terms_and_conditions.title',
            leading: null,
          ),
          Padding(
            padding: EdgeInsets.all(theme.defaultSpacing),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TranslatedText(
                  'new_terms_and_conditions.explanation',
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: theme.hugeSpacing),
                CupertinoTheme(
                  data: CupertinoThemeData(primaryColor: theme.link),
                  child: CupertinoButton(
                    onPressed: () {
                      IrmaRepositoryProvider.of(context).openURL(termsUrl);
                      setState(() {
                        viewedNewTerms = true;
                      });
                    },
                    child: TranslatedText('new_terms_and_conditions.read_terms'),
                  ),
                ),
              ],
            ),
          ),
          IrmaBottomBar(
            primaryButtonLabel: 'new_terms_and_conditions.accept',
            secondaryButtonLabel: 'new_terms_and_conditions.dismiss',
            onPrimaryPressed: viewedNewTerms
                ? () async {
                    await prefs.markLatestTermsAsAccepted(true);
                    if (context.mounted) {
                      context.pop();
                    }
                  }
                : null,
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

// Screen to show when terms and conditions have changed
class TermsChangedScreen extends StatefulWidget {
  const TermsChangedScreen({super.key});

  @override
  State<TermsChangedScreen> createState() => _TermsChangedScreenState();
}

class _TermsChangedScreenState extends State<TermsChangedScreen> {
  bool viewedNewTerms = false;

  @override
  Widget build(BuildContext context) {
    final prefs = IrmaRepositoryProvider.of(context).preferences;

    final termsUrl = (FlutterI18n.currentLocale(context)?.languageCode ?? 'en') == 'nl'
        ? IrmaPreferences.mostRecentTermsUrlNl
        : IrmaPreferences.mostRecentTermsUrlEn;

    final theme = IrmaTheme.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: IrmaAppBar(
          titleTranslationKey: 'new_terms_and_conditions.title',
          leading: null,
        ),
        body: Padding(
          padding: EdgeInsets.all(theme.defaultSpacing),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TranslatedText(
                'new_terms_and_conditions.explanation',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: theme.hugeSpacing),
              CupertinoTheme(
                data: CupertinoThemeData(primaryColor: theme.link),
                child: CupertinoButton(
                  onPressed: () {
                    IrmaRepositoryProvider.of(context).openURL(termsUrl);
                    setState(() {
                      viewedNewTerms = true;
                    });
                  },
                  child: TranslatedText('new_terms_and_conditions.read_terms'),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: IrmaBottomBar(
          primaryButtonLabel: 'new_terms_and_conditions.accept',
          secondaryButtonLabel: 'new_terms_and_conditions.reject',
          onPrimaryPressed: viewedNewTerms
              ? () async {
                  await prefs.markLatestTermsAsAccepted(true);
                }
              : null,
          onSecondaryPressed: () async {
            final userConfirmsDelete = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return IrmaConfirmationDialog(
                      titleTranslationKey: 'new_terms_and_conditions.reject_dialog.title',
                      contentTranslationKey: 'new_terms_and_conditions.reject_dialog.body',
                      cancelTranslationKey: 'new_terms_and_conditions.reject_dialog.cancel',
                      confirmTranslationKey: 'new_terms_and_conditions.reject_dialog.delete',
                      onCancelPressed: () => context.pop(false),
                      onConfirmPressed: () => context.pop(true),
                    );
                  },
                ) ??
                false;

            if (userConfirmsDelete && context.mounted) {
              IrmaRepositoryProvider.of(context).bridgedDispatch(
                ClearAllDataEvent(),
              );
            }
          },
        ),
      ),
    );
  }
}
