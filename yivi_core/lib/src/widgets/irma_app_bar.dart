import "package:flutter/material.dart";

import "../theme/theme.dart";
import "irma_icon_button.dart";
import "translated_text.dart";

class YiviAppBarQrCodeButton extends StatelessWidget {
  const YiviAppBarQrCodeButton({super.key, this.onTap});

  final Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final spacing = context.yivi.spacing.small;

    // The old left/top-only padding sat inside the ink area, cramming the ripple
    // against the icon's right/bottom. Split that offset: half outside the
    // button (positioning, doesn't touch the ripple) and half as symmetric
    // padding inside (so the highlight is centred on the icon). The two halves
    // sum to the original offset, so the icon stays where it was.
    return Padding(
      padding: EdgeInsets.only(left: spacing, top: spacing),
      child: IrmaIconButton(
        padding: EdgeInsets.all(spacing),
        icon: Icons.qr_code_scanner_rounded,
        size: 32,
        onTap: onTap ?? () {},
      ),
    );
  }
}

class YiviBackButton extends StatelessWidget {
  final Function()? onTap;

  const YiviBackButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return IrmaIconButton(
      key: const Key("irma_app_bar_leading"),
      icon: Icons.arrow_back_sharp,
      semanticsLabelKey: "ui.go_back",
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
  final String? titleString;
  final Widget? title;
  final Widget? leading;
  final List<Widget> actions;
  final bool hasBorder;

  IrmaAppBar({
    this.titleTranslationKey,
    this.titleString,
    this.title,
    this.leading = const YiviBackButton(),
    this.actions = const [],
    this.hasBorder = true,
  }) : assert(
         [title, titleTranslationKey, titleString].nonNulls.length == 1,
         "only one of them can be non-null",
       );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      key: const Key("irma_app_bar"),
      shape: hasBorder
          ? Border(bottom: BorderSide(color: context.colors.tertiary))
          : null,
      leading: leading,
      title:
          title ?? TranslatedText(titleTranslationKey ?? (titleString ?? "")),
      actions: actions,
      automaticallyImplyLeading: false,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
