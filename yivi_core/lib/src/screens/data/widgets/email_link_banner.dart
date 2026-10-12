import "dart:math";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../providers/email_linking_provider.dart";
import "../../../theme/theme.dart";
import "../../../util/email_linking.dart";
import "../../../widgets/irma_icon_button.dart";
import "../../../widgets/link.dart";
import "../../../widgets/translated_text.dart";
import "../../../widgets/yivi_themed_button.dart";

const _shieldSize = 32.0;
const _closeIconSize = 18.0;
// 18 px icon plus this padding on both sides makes the 44 px touch target.
const _closePadding = 13.0;
// Inset of the close button from the top and right edge of the banner.
const _closeInset = 2.0;
// Keeps the text out from under the close button.
const _textEndPadding = 28.0;
const _bannerGap = 12.0;

const _sheetRadius = 16.0;
const _sheetHandleWidth = 40.0;
const _sheetHandleHeight = 4.0;
const _sheetScrimOpacity = 0.45;
// Bottom padding of the sheet, which also has to clear the gesture area.
const _sheetBottomPadding = 32.0;

/// Banner at the top of the Gegevens tab that asks the user to link an e-mail
/// address, so the app can be blocked remotely (`FeatureFlag.emailLinking`).
class EmailLinkBanner extends ConsumerWidget {
  const EmailLinkBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = IrmaTheme.of(context);

    // The list below has its own 16 px top padding, so this adds up to the
    // 24 px between the banner and its first card.
    return Padding(
      padding: EdgeInsets.fromLTRB(
        theme.defaultSpacing,
        theme.defaultSpacing,
        theme.defaultSpacing,
        theme.smallSpacing,
      ),
      child: Container(
        key: const Key("email_link_banner"),
        decoration: BoxDecoration(
          color: theme.tertiary,
          borderRadius: theme.borderRadius,
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(theme.defaultSpacing),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.verified_user,
                    color: theme.link,
                    size: _shieldSize,
                  ),
                  const SizedBox(width: _bannerGap),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: _textEndPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            child: TranslatedText(
                              "email_linking.banner.title",
                              style: theme.textTheme.bodyLarge!.copyWith(
                                height: 22 / 16,
                              ),
                            ),
                          ),
                          SizedBox(height: theme.tinySpacing),
                          TranslatedText(
                            "email_linking.banner.body",
                            style: theme.textTheme.bodyMedium!.copyWith(
                              fontSize: 14,
                              height: 20 / 14,
                            ),
                          ),
                          SizedBox(height: theme.smallSpacing),
                          Link(
                            label: "email_linking.banner.link",
                            style: const TextStyle(
                              fontSize: 14,
                              height: 20 / 14,
                            ),
                            onTap: () => openEmailLinking(context, ref),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: _closeInset,
              right: _closeInset,
              child: KeyedSubtree(
                key: const Key("email_link_banner_close"),
                child: IrmaIconButton(
                  icon: Icons.close,
                  size: _closeIconSize,
                  padding: const EdgeInsets.all(_closePadding),
                  color: theme.dark,
                  semanticsLabelKey: "email_linking.banner.close",
                  onTap: () => _showLaterSheet(context, ref),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Asks what to do with the banner: show it again later, or never.
Future<void> _showLaterSheet(BuildContext context, WidgetRef ref) {
  final linking = ref.read(emailLinkingProvider.notifier);
  // The banner leaves the tree as soon as it is snoozed or dismissed, so take
  // the navigator now instead of looking it up from the banner's context.
  final navigator = Navigator.of(context);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    barrierColor: Colors.black.withValues(alpha: _sheetScrimOpacity),
    builder: (_) => _LaterSheet(
      onRemindMe: () {
        navigator.pop();
        linking.snoozeBanner();
      },
      onDismiss: () {
        navigator.pop();
        linking.dismissBanner();
      },
    ),
  );
}

class _LaterSheet extends StatelessWidget {
  final VoidCallback onRemindMe;
  final VoidCallback onDismiss;

  const _LaterSheet({required this.onRemindMe, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final gap = theme.smallSpacing + theme.tinySpacing;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.surfacePrimary,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(_sheetRadius),
        ),
      ),
      // Scrolls for a landscape screen or a large text size.
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          theme.mediumSpacing,
          gap,
          theme.mediumSpacing,
          max(_sheetBottomPadding, MediaQuery.paddingOf(context).bottom),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: _sheetHandleWidth,
                height: _sheetHandleHeight,
                decoration: BoxDecoration(
                  color: theme.neutralLight,
                  borderRadius: BorderRadius.circular(_sheetHandleHeight / 2),
                ),
              ),
            ),
            SizedBox(height: gap + theme.smallSpacing),
            Semantics(
              header: true,
              child: TranslatedText(
                "email_linking.later.title",
                style: theme.textTheme.bodyLarge!.copyWith(
                  fontSize: 18,
                  height: 26 / 18,
                  color: theme.neutralExtraDark,
                ),
              ),
            ),
            SizedBox(height: gap),
            TranslatedText(
              "email_linking.later.body",
              style: theme.textTheme.bodyMedium,
            ),
            SizedBox(height: gap + theme.smallSpacing),
            YiviThemedButton(
              key: const Key("email_link_later_remind"),
              label: "email_linking.later.remind_me",
              size: YiviButtonSize.slim,
              onPressed: onRemindMe,
            ),
            SizedBox(height: theme.smallSpacing),
            YiviThemedButton(
              key: const Key("email_link_later_dismiss"),
              label: "email_linking.later.dismiss",
              style: YiviButtonStyle.outlined,
              size: YiviButtonSize.slim,
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}
