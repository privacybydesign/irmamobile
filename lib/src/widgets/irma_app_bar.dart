import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'irma_icon_button.dart';
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
  final bool hasBorder;

  const IrmaAppBar({
    this.titleTranslationKey,
    this.title,
    this.leadingIcon,
    this.leadingAction,
    this.leadingTooltip,
    this.leadingCancel,
    this.noLeading = false,
    this.actions = const [],
    this.hasBorder = true,
  }) : assert((titleTranslationKey == null && title != null) || title == null && titleTranslationKey != null);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return AppBar(
      key: const Key('irma_app_bar'),
      backgroundColor: theme.light,
      shape: hasBorder
          ? Border(
              bottom: BorderSide(
                color: theme.tertiary,
              ),
            )
          : null,
      centerTitle: true,
      leading: noLeading
          ? null
          : IrmaIconButton(
              key: const Key('irma_app_bar_leading'),
              icon: Icons.arrow_back_sharp,
              onTap: () {
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
