import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../theme/theme.dart';

class YiviDialog extends StatelessWidget {
  const YiviDialog({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return AnimatedPadding(
      padding: MediaQuery.of(context).viewInsets +
          EdgeInsets.symmetric(
            horizontal: theme.mediumSpacing,
            vertical: theme.defaultSpacing,
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
                  color: theme.surfacePrimary,
                  elevation: 24.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(theme.smallSpacing),
                  ),
                  type: MaterialType.card,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(theme.smallSpacing),
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
    final theme = IrmaTheme.of(context);

    return AnimatedPadding(
      padding: MediaQuery.of(context).viewInsets +
          EdgeInsets.symmetric(
            horizontal: theme.mediumSpacing,
            vertical: theme.defaultSpacing,
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
                color: theme.surfacePrimary,
                elevation: 24.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(theme.smallSpacing),
                ),
                type: MaterialType.card,
                child: Stack(
                  children: [
                    Container(
                      margin: EdgeInsets.all(theme.defaultSpacing),
                      key: const Key('irma_dialog'),
                      child: ListView(
                        shrinkWrap: true,
                        addSemanticIndexes: false,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(bottom: theme.defaultSpacing),
                            child: Column(
                              children: [
                                Semantics(
                                  namesRoute: !Platform.isIOS, // Set to false on iOS to prevent double read
                                  label: FlutterI18n.translate(context, 'accessibility.alert'),
                                  child: Text(
                                    title,
                                    key: const Key('irma_dialog_title'),
                                    style: theme.textTheme.displaySmall,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                SizedBox(height: theme.mediumSpacing),
                                Text(
                                  content,
                                  key: const Key('irma_dialog_content'),
                                  style: theme.textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                                if (image != null) ...[
                                  SizedBox(height: theme.defaultSpacing),
                                  Center(
                                    child: Image.asset(
                                      image!,
                                      width: 240,
                                    ),
                                  ),
                                ]
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
