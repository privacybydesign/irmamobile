import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'translated_text.dart';

// A search bar that can be used in place of an AppBar in a Scaffold.
class YiviSearchBar extends StatelessWidget implements PreferredSizeWidget {
  final FocusNode focusNode;
  final Function() onCancel;
  final Function(String) onQueryChanged;
  final bool hasBorder;

  const YiviSearchBar({
    super.key,
    required this.focusNode,
    required this.onCancel,
    required this.onQueryChanged,
    this.hasBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.backgroundPrimary,
        border: Border(bottom: BorderSide(color: theme.tertiary)),
      ),
      child: SafeArea(
        child: Container(
          height: preferredSize.height,
          padding: EdgeInsets.only(left: theme.defaultSpacing, right: theme.smallSpacing),
          child: Row(
            children: [
              Expanded(
                child: CupertinoSearchTextField(
                  key: const Key('search_bar'),
                  focusNode: focusNode,
                  onChanged: onQueryChanged,
                ),
              ),
              TextButton(
                key: const Key('cancel_search_button'),
                onPressed: onCancel,
                child: TranslatedText(
                  'search.cancel',
                  style: theme.textButtonTextStyle.copyWith(
                    fontWeight: FontWeight.normal,
                    color: theme.link,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
