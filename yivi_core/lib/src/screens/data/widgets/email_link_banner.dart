import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../providers/email_linking_provider.dart";
import "../../../theme/theme.dart";
import "../../../theme/yivi_corners.dart";
import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_space.dart";
import "../../../util/i18n.dart";
import "../../../widgets/buttons/close_button.dart";
import "../../../widgets/buttons/link.dart";
import "../../../widgets/buttons/pill_buttons.dart";
import "../../../widgets/sheet/glass_sheet.dart";
import "../../../widgets/text/translated_text.dart";
import "../../add_data/email_linking.dart";

/// Banner at the top of the Data tab that asks the user to link an e-mail
/// address, so the app can be blocked remotely.
class EmailLinkBanner extends ConsumerWidget {
  const EmailLinkBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = IrmaTheme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        YiviSpace.x16,
        YiviSpace.x16,
        YiviSpace.x16,
        0,
      ),
      child: DecoratedBox(
        key: const Key("email_link_banner"),
        // A tinted card with an outline, the same off a sheet and on it.
        decoration: ShapeDecoration(
          color: YiviPalette.forBrightness(Theme.of(context).brightness).tint,
          shape: RoundedRectangleBorder(
            borderRadius: YiviCorners.cardRadius,
            side: BorderSide(
              color: YiviPalette.forBrightness(
                Theme.of(context).brightness,
              ).outline,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(
            left: YiviSpace.x16,
            top: YiviSpace.x8,
            bottom: YiviSpace.x16,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: YiviSpace.x8),
                child: Icon(
                  Icons.shield_outlined,
                  color: YiviPalette.of(context).link,
                  size: 28,
                ),
              ),
              const SizedBox(width: YiviSpace.x16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: YiviSpace.x8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: TranslatedText(
                          "email_linking.banner.title",
                          style: theme.textTheme.headlineMedium!.copyWith(
                            fontSize: 16,
                            color: YiviPalette.of(context).text,
                          ),
                        ),
                      ),
                      const SizedBox(height: YiviSpace.x4),
                      TranslatedText(
                        "email_linking.banner.body",
                        style: theme.textTheme.bodyMedium!.copyWith(
                          fontSize: 14,
                          color: YiviPalette.of(context).heading,
                        ),
                      ),
                      const SizedBox(height: YiviSpace.x8),
                      Link(
                        label: "email_linking.banner.link",
                        onTap: () => openEmailLinking(context),
                      ),
                    ],
                  ),
                ),
              ),
              KeyedSubtree(
                key: const Key("email_link_banner_close"),
                child: YiviCloseButton(
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

  return showTitledGlassSheet(
    context: context,
    titleKey: "email_linking.later.title",
    child: Padding(
      padding: const EdgeInsets.all(YiviSpace.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.tr("email_linking.later.body"),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: YiviSpace.x24),
          FancyPillButton(
            key: const Key("email_link_later_remind"),
            label: context.tr("email_linking.later.remind_me"),
            size: PillSize.regular,
            onPressed: () {
              navigator.pop();
              linking.snoozeBanner();
            },
          ),
          const SizedBox(height: YiviSpace.x8),
          PillButton(
            key: const Key("email_link_later_dismiss"),
            label: context.tr("email_linking.later.dismiss"),
            style: PillStyle.outlined,
            onPressed: () {
              navigator.pop();
              linking.dismissBanner();
            },
          ),
          const SizedBox(height: YiviSpace.x16),
        ],
      ),
    ),
  );
}
