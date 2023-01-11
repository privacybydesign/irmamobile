import 'package:flutter/material.dart';
import 'package:irmamobile/src/widgets/irma_icon_button.dart';

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
      backgroundColor: theme.light,
      key: const Key('irma_app_bar'),
      centerTitle: true,
      leading: noLeading
          ? null
          : Padding(
              padding: const EdgeInsets.all(12),
              child: IrmaIconButton(
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
              )),
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
