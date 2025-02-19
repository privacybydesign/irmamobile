import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'irma_icon_button.dart';
import 'translated_text.dart';

class YiviBackButton extends StatelessWidget {
  final Function()? onTap;

  const YiviBackButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return IrmaIconButton(
      key: const Key('irma_app_bar_leading'),
      icon: Icons.arrow_back_sharp,
      semanticsLabelKey: 'ui.go_back',
      onTap: () {
        if (onTap == null) {
          Navigator.of(context).pop();
        } else {
          onTap!();
        }
      },
    );
  }
}

class IrmaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? titleTranslationKey;
  final String? title;
  final Widget? leading;
  final List<Widget> actions;
  final bool hasBorder;

  const IrmaAppBar({
    this.titleTranslationKey,
    this.title,
    this.leading = const YiviBackButton(),
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
      leading: leading,
      title: TranslatedText(
        titleTranslationKey ?? (title ?? ''),
        style: theme.textTheme.displaySmall,
      ),
      actions: actions,
      automaticallyImplyLeading: false,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
