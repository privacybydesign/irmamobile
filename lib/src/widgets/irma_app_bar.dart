import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../theme/theme.dart';
import 'translated_text.dart';

class IrmaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? titleTranslationKey;
  final String? title;
  final Icon? leadingIcon;
  final void Function()? leadingAction;
  final void Function()? leadingCancel;
  final String? leadingTooltip;
  final List<Widget> actions;
  final bool noLeading;

  const IrmaAppBar({
    this.titleTranslationKey,
    this.title,
    this.leadingIcon,
    this.leadingAction,
    this.leadingTooltip,
    this.leadingCancel,
    this.noLeading = false,
    this.actions = const [],
  }) : assert((titleTranslationKey == null && title != null) || title == null && titleTranslationKey != null);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return AppBar(
      backgroundColor: theme.themeData.colorScheme.background,
      key: const Key('irma_app_bar'),
      centerTitle: true,
      leading: noLeading
          ? null
          : Padding(
              padding: const EdgeInsets.all(12),
              child: CircleAvatar(
                backgroundColor: Colors.grey.shade300,
                child: IconButton(
                  enableFeedback: true,
                  key: const Key('irma_app_bar_leading'),
                  icon: leadingIcon ??
                      Icon(
                        Icons.arrow_back_ios_new,
                        semanticLabel: FlutterI18n.translate(context, 'accessibility.back'),
                        size: 16.0,
                        color: Colors.grey.shade800,
                      ),
                  tooltip: leadingTooltip,
                  onPressed: () {
                    if (leadingCancel != null) {
                      leadingCancel!();
                    }
                    if (leadingAction == null) {
                      Navigator.of(context).pop();
                    } else {
                      leadingAction!();
                    }
                  },
                ),
              ),
            ),
      title: TranslatedText(
        titleTranslationKey ?? (title ?? ''),
        style: theme.textTheme.headline3,
      ),
      actions: actions,
      automaticallyImplyLeading: false,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
