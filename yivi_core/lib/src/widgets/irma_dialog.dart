import "dart:io";

import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";

import "../theme/theme.dart";

class YiviDialog extends StatelessWidget {
  const YiviDialog({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dialogTheme = Theme.of(context).dialogTheme;
    final shape = dialogTheme.shape as RoundedRectangleBorder?;

    return AnimatedPadding(
      padding:
          MediaQuery.of(context).viewInsets +
          EdgeInsets.symmetric(
            horizontal: context.yivi.spacing.medium,
            vertical: context.yivi.spacing.base,
          ),
      duration: const Duration(milliseconds: 100),
      curve: Curves.decelerate,
      child: MediaQuery.removeViewInsets(
        removeLeft: true,
        removeTop: true,
        removeRight: true,
        removeBottom: true,
        context: context,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                scopesRoute: true,
                explicitChildNodes: true,
                child: Material(
                  color: dialogTheme.backgroundColor,
                  elevation: dialogTheme.elevation!,
                  shape: dialogTheme.shape,
                  type: MaterialType.card,
                  child: ClipRRect(
                    borderRadius:
                        shape?.borderRadius as BorderRadius? ??
                        BorderRadius.zero,
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IrmaDialog extends StatelessWidget {
  final String title;
  final String content;
  final Widget child;
  final String? image;

  const IrmaDialog({
    required this.title,
    required this.content,
    required this.child,
    this.image,
  });

  @override
  Widget build(BuildContext context) {
    final dialogTheme = Theme.of(context).dialogTheme;

    return AnimatedPadding(
      padding:
          MediaQuery.of(context).viewInsets +
          EdgeInsets.symmetric(
            horizontal: context.yivi.spacing.medium,
            vertical: context.yivi.spacing.base,
          ),
      duration: const Duration(milliseconds: 100),
      curve: Curves.decelerate,
      child: MediaQuery.removeViewInsets(
        removeLeft: true,
        removeTop: true,
        removeRight: true,
        removeBottom: true,
        context: context,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 280.0),
            child: Semantics(
              scopesRoute: true,
              explicitChildNodes: true,
              child: Material(
                color: dialogTheme.backgroundColor,
                elevation: dialogTheme.elevation ?? 24.0,
                shape: dialogTheme.shape,
                type: MaterialType.card,
                child: Stack(
                  children: [
                    Container(
                      margin: EdgeInsets.all(context.yivi.spacing.base),
                      key: const Key("irma_dialog"),
                      child: ListView(
                        shrinkWrap: true,
                        addSemanticIndexes: false,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: context.yivi.spacing.base,
                            ),
                            child: Column(
                              children: [
                                Semantics(
                                  namesRoute: !Platform
                                      .isIOS, // Set to false on iOS to prevent double read
                                  label: FlutterI18n.translate(
                                    context,
                                    "accessibility.alert",
                                  ),
                                  child: Text(
                                    title,
                                    key: const Key("irma_dialog_title"),
                                    style: dialogTheme.titleTextStyle,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                SizedBox(height: context.yivi.spacing.medium),
                                Text(
                                  content,
                                  key: const Key("irma_dialog_content"),
                                  style: dialogTheme.contentTextStyle,
                                  textAlign: TextAlign.center,
                                ),
                                if (image != null) ...[
                                  SizedBox(height: context.yivi.spacing.base),
                                  Center(
                                    child: Image.asset(image!, width: 240),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          child,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
