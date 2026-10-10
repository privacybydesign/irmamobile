import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../providers/email_linking_provider.dart";
import "../../../theme/theme.dart";
import "../../../util/email_linking.dart";
import "../../../widgets/irma_card.dart";
import "../../../widgets/irma_close_button.dart";
import "../../../widgets/link.dart";
import "../../../widgets/translated_text.dart";
import "../../../widgets/yivi_bottom_sheet.dart";
import "../../../widgets/yivi_themed_button.dart";

/// Banner at the top of the Gegevens tab that asks the user to link an e-mail
/// address, so the app can be blocked remotely (`FeatureFlag.emailLinking`).
class EmailLinkBanner extends ConsumerWidget {
  const EmailLinkBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = IrmaTheme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        theme.defaultSpacing,
        theme.defaultSpacing,
        theme.defaultSpacing,
        0,
      ),
      child: IrmaCard(
        key: const Key("email_link_banner"),
        style: IrmaCardStyle.highlighted,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.only(
            left: theme.defaultSpacing,
            top: theme.smallSpacing,
            bottom: theme.defaultSpacing,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: theme.smallSpacing),
                child: Icon(Icons.shield_outlined, color: theme.link, size: 28),
              ),
              SizedBox(width: theme.defaultSpacing),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: theme.smallSpacing),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: TranslatedText(
                          "email_linking.banner.title",
                          style: theme.textTheme.headlineMedium!.copyWith(
                            fontSize: 16,
                            color: theme.dark,
                          ),
                        ),
                      ),
                      SizedBox(height: theme.tinySpacing),
                      TranslatedText(
                        "email_linking.banner.body",
                        style: theme.textTheme.bodyMedium!.copyWith(
                          fontSize: 14,
                          color: theme.neutralExtraDark,
                        ),
                      ),
                      SizedBox(height: theme.smallSpacing),
                      Link(
                        label: "email_linking.banner.link",
                        onTap: () => openEmailLinking(context, ref),
                      ),
                    ],
                  ),
                ),
              ),
              KeyedSubtree(
                key: const Key("email_link_banner_close"),
                child: IrmaCloseButton(
                  onTap: () => _showLaterSheet(context, ref),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Asks what to do with the banner: show it again later, or never.
Future<void> _showLaterSheet(BuildContext context, WidgetRef ref) {
  final theme = IrmaTheme.of(context);
  final linking = ref.read(emailLinkingProvider.notifier);
  // The banner leaves the tree as soon as it is snoozed or dismissed, so take
  // the navigator now instead of looking it up from the banner's context.
  final navigator = Navigator.of(context);

  return showYiviBottomSheet(
    context: context,
    titleKey: "email_linking.later.title",
    child: Padding(
      padding: EdgeInsets.all(theme.defaultSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            FlutterI18n.translate(context, "email_linking.later.body"),
            style: theme.textTheme.bodyMedium,
          ),
          SizedBox(height: theme.mediumSpacing),
          YiviThemedButton(
            key: const Key("email_link_later_remind"),
            label: "email_linking.later.remind_me",
            onPressed: () {
              navigator.pop();
              linking.snoozeBanner();
            },
          ),
          SizedBox(height: theme.smallSpacing),
          YiviThemedButton(
            key: const Key("email_link_later_dismiss"),
            label: "email_linking.later.dismiss",
            style: YiviButtonStyle.outlined,
            onPressed: () {
              navigator.pop();
              linking.dismissBanner();
            },
          ),
          SizedBox(height: theme.defaultSpacing),
        ],
      ),
    ),
  );
}
