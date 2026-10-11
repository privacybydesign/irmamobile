import "package:material_ui/material_ui.dart";

import "../../../theme/theme.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_close_button.dart";

class SessionScaffold extends StatelessWidget {
  final Widget? body, bottomNavigationBar;
  final String appBarTitle;
  final VoidCallback? onDismiss;
  final VoidCallback? onPrevious;

  /// The grey-white of the session screens unless given.
  final Color? backgroundColor;

  const SessionScaffold({
    Key? key,
    this.onDismiss,
    this.onPrevious,
    this.bottomNavigationBar,
    this.body,
    this.backgroundColor,
    required this.appBarTitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Scaffold(
      backgroundColor: backgroundColor ?? theme.backgroundSecondary,
      bottomNavigationBar: bottomNavigationBar,
      body: body,
      appBar: IrmaAppBar(
        titleTranslationKey: appBarTitle,
        leading: onPrevious != null ? YiviBackButton(onTap: onPrevious) : null,
        actions: [
          if (onDismiss != null)
            Padding(
              padding: EdgeInsets.only(right: theme.defaultSpacing),
              child: IrmaCloseButton(onTap: onDismiss),
            ),
        ],
      ),
    );
  }
}
