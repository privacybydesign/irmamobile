import "dart:io";

import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";

import "../theme/theme.dart";
import "yivi_themed_button.dart";

/// Modal dialog frame. Wraps its child in the standard Yivi dialog chrome:
/// AnimatedPadding for the keyboard viewInsets, a Material card with the
/// theme's background/elevation/shape, and the route-scoping Semantics
/// expected by accessibility tooling.
///
/// Three construction modes:
///
///  - Default constructor: pass any [child] for full layout control.
///  - [YiviDialog.structured]: built-in centered title + content + optional
///    image + action [child] layout, with a 280dp minimum width.
///  - [YiviDialog.confirmation]: structured layout with confirm + cancel
///    buttons. Translation keys are resolved at build time.
class YiviDialog extends StatelessWidget {
  /// Optional minimum-width constraint (in logical pixels). Useful for
  /// structured dialogs that should not shrink below a readable width.
  final double? minWidth;
  final Widget child;

  const YiviDialog({super.key, required this.child, this.minWidth});

  /// Structured dialog with a centered title, content paragraph, optional
  /// image, and an action area (the [child]). Uses a ListView body so
  /// content can scroll on small screens.
  YiviDialog.structured({
    super.key,
    required String title,
    required String content,
    required Widget child,
    String? image,
  }) : child = _StructuredBody(
         title: title,
         content: content,
         actions: child,
         image: image,
       ),
       minWidth = 280;

  /// Confirmation dialog with a translated title, content paragraph, and
  /// a stacked confirm + cancel button pair.
  ///
  /// By default the confirm button is the visually emphasised "fancy"
  /// action. Set [nudgeCancel] to true to flip emphasis to the cancel
  /// button (e.g. destructive confirmations where cancel is the safer
  /// default). Button callbacks default to popping the route with `true`
  /// or `false` respectively.
  YiviDialog.confirmation({
    super.key,
    required String titleTranslationKey,
    required String contentTranslationKey,
    Map<String, String>? contentTranslationParams,
    String? cancelTranslationKey,
    VoidCallback? onCancelPressed,
    String? confirmTranslationKey,
    VoidCallback? onConfirmPressed,
    bool nudgeCancel = false,
  }) : child = _ConfirmationBody(
         titleTranslationKey: titleTranslationKey,
         contentTranslationKey: contentTranslationKey,
         contentTranslationParams: contentTranslationParams,
         cancelTranslationKey: cancelTranslationKey,
         onCancelPressed: onCancelPressed,
         confirmTranslationKey: confirmTranslationKey,
         onConfirmPressed: onConfirmPressed,
         nudgeCancel: nudgeCancel,
       ),
       minWidth = 280;

  @override
  Widget build(BuildContext context) {
    final dialogTheme = Theme.of(context).dialogTheme;
    final shape = dialogTheme.shape as RoundedRectangleBorder?;

    Widget card = Material(
      color: dialogTheme.backgroundColor,
      elevation: dialogTheme.elevation!,
      shape: dialogTheme.shape,
      type: MaterialType.card,
      child: ClipRRect(
        borderRadius:
            shape?.borderRadius as BorderRadius? ?? BorderRadius.zero,
        child: child,
      ),
    );

    if (minWidth != null) {
      card = ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth!),
        child: card,
      );
    }

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
                child: card,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StructuredBody extends StatelessWidget {
  final String title;
  final String content;
  final Widget actions;
  final String? image;

  const _StructuredBody({
    required this.title,
    required this.content,
    required this.actions,
    this.image,
  });

  @override
  Widget build(BuildContext context) {
    final dialogTheme = Theme.of(context).dialogTheme;

    return Container(
      margin: EdgeInsets.all(context.yivi.spacing.base),
      key: const Key("irma_dialog"),
      child: ListView(
        shrinkWrap: true,
        addSemanticIndexes: false,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: context.yivi.spacing.base),
            child: Column(
              children: [
                Semantics(
                  // false on iOS to prevent double read
                  namesRoute: !Platform.isIOS,
                  label: FlutterI18n.translate(context, "accessibility.alert"),
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
                  Center(child: Image.asset(image!, width: 240)),
                ],
              ],
            ),
          ),
          actions,
        ],
      ),
    );
  }
}

class _ConfirmationBody extends StatelessWidget {
  final String titleTranslationKey;
  final String contentTranslationKey;
  final Map<String, String>? contentTranslationParams;
  final String? cancelTranslationKey;
  final VoidCallback? onCancelPressed;
  final String? confirmTranslationKey;
  final VoidCallback? onConfirmPressed;
  final bool nudgeCancel;

  const _ConfirmationBody({
    required this.titleTranslationKey,
    required this.contentTranslationKey,
    this.contentTranslationParams,
    this.cancelTranslationKey,
    this.onCancelPressed,
    this.confirmTranslationKey,
    this.onConfirmPressed,
    this.nudgeCancel = false,
  });

  @override
  Widget build(BuildContext context) {
    final confirmButton = YiviThemedButton(
      key: const Key("dialog_confirm_button"),
      onPressed: onConfirmPressed ?? () => Navigator.of(context).pop(true),
      label: confirmTranslationKey ?? "ui.confirm",
      style: !nudgeCancel ? YiviButtonStyle.fancy : YiviButtonStyle.outlined,
    );

    final cancelButton = YiviThemedButton(
      key: const Key("dialog_cancel_button"),
      onPressed: onCancelPressed ?? () => Navigator.of(context).pop(false),
      label: cancelTranslationKey ?? "ui.cancel",
      style: nudgeCancel ? YiviButtonStyle.fancy : YiviButtonStyle.outlined,
    );

    final spacer = SizedBox(height: context.yivi.spacing.small);

    var buttons = [confirmButton, spacer, cancelButton];
    if (nudgeCancel) buttons = buttons.reversed.toList();

    return _StructuredBody(
      title: FlutterI18n.translate(context, titleTranslationKey),
      content: FlutterI18n.translate(
        context,
        contentTranslationKey,
        translationParams: contentTranslationParams,
      ),
      actions: Column(children: buttons),
    );
  }
}
