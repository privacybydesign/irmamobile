import "package:cupertino_ui/cupertino_ui.dart";
import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";
import "package:share_plus/share_plus.dart";

import "../../../providers/irma_repository_provider.dart";
import "../../../sentry/sentry.dart";
import "../../../theme/theme.dart";
import "../../../theme/yivi_palette.dart";
import "../../../widgets/irma_dialog.dart";
import "../../../widgets/translated_text.dart";
import "../../../widgets/yivi_themed_button.dart";

class ContactLinkTile extends StatelessWidget {
  final IconData? iconData;
  final String labelTranslationKey;

  const ContactLinkTile({
    super.key,
    this.iconData,
    required this.labelTranslationKey,
  });

  @override
  Widget build(BuildContext context) {
    return Tile(
      iconData: iconData,
      labelTranslationKey: labelTranslationKey,
      onTap: () async {
        final String address = FlutterI18n.translate(context, "help.contact");
        final String subject = Uri.encodeComponent(
          FlutterI18n.translate(context, "help.mail_subject"),
        );
        final mail = "mailto:$address?subject=$subject";
        try {
          await IrmaRepositoryProvider.of(context).openURLExternally(mail);
        } catch (_) {
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return IrmaDialog(
                  title: FlutterI18n.translate(
                    context,
                    "help.mail_error_title",
                  ),
                  content: FlutterI18n.translate(context, "help.mail_error"),
                  child: YiviThemedButton(
                    label: "help.mail_error_button",
                    onPressed: () => Navigator.pop(context),
                  ),
                );
              },
            );
          }
        }
      },
    );
  }
}

class ShareLinkTile extends StatelessWidget {
  final IconData iconData;
  final String labelTranslationKey;
  final String shareTextKey;

  const ShareLinkTile({
    super.key,
    required this.iconData,
    required this.labelTranslationKey,
    required this.shareTextKey,
  });

  @override
  Widget build(BuildContext context) {
    return Tile(
      iconData: iconData,
      labelTranslationKey: labelTranslationKey,
      onTap: () {
        final RenderBox box = context.findRenderObject() as RenderBox;
        SharePlus.instance.share(
          ShareParams(
            text: FlutterI18n.translate(context, shareTextKey),
            sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
          ),
        );
      },
    );
  }
}

class ExternalLinkTile extends StatelessWidget {
  final IconData? iconData;
  final String labelTranslationKey;
  final String urlLinkKey;

  const ExternalLinkTile({
    super.key,
    this.iconData,
    required this.labelTranslationKey,
    required this.urlLinkKey,
  });

  @override
  Widget build(BuildContext context) {
    return Tile(
      iconData: iconData,
      labelTranslationKey: labelTranslationKey,
      onTap: () {
        try {
          IrmaRepositoryProvider.of(
            context,
          ).openURL(FlutterI18n.translate(context, urlLinkKey));
        } catch (e, stacktrace) {
          // TODO: consider whether we want error screen here
          reportError(e, stacktrace);
        }
      },
    );
  }
}

class InternalLinkTile extends StatelessWidget {
  final IconData? iconData;
  final String labelTranslationKey;
  final Function() onTap;

  const InternalLinkTile({
    super.key,
    this.iconData,
    required this.labelTranslationKey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tile(
      isLink: false,
      iconData: iconData,
      labelTranslationKey: labelTranslationKey,
      onTap: onTap,
    );
  }
}

class ToggleTile extends StatelessWidget {
  final IconData? iconData;
  final String labelTranslationKey;
  final void Function(bool) onChanged;
  final Stream<bool> stream;

  const ToggleTile({
    super.key,
    this.iconData,
    required this.labelTranslationKey,
    required this.onChanged,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return StreamBuilder(
      stream: stream,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        final value = snapshot.hasData && snapshot.data!;

        void toggle(bool newValue) {
          HapticFeedback.selectionClick();
          onChanged(newValue);
        }

        return Semantics(
          value: FlutterI18n.translate(
            context,
            value ? "switch.describe_state_on" : "switch.describe_state_off",
          ),
          hint: FlutterI18n.translate(
            context,
            value ? "switch.hint_state_on" : "switch.hint_state_off",
          ),
          child: Tile(
            isLink: false,
            iconData: iconData,
            labelTranslationKey: labelTranslationKey,
            // Tapping anywhere on the row toggles the switch.
            onTap: () => toggle(!value),
            // The switch handles its own taps/drags too: a disabled
            // (onChanged: null) CupertinoSwitch swallows the gesture before it
            // reaches the Tile's onTap, so it must stay interactive.
            trailing: CupertinoSwitch(
              value: value,
              onChanged: toggle,
              activeTrackColor: theme.success,
            ),
          ),
        );
      },
    );
  }
}

class Tile extends StatelessWidget {
  final IconData? iconData;
  final String labelTranslationKey;
  final Function() onTap;
  final Widget? trailing;
  final bool isLink;

  const Tile({
    super.key,
    this.iconData,
    required this.labelTranslationKey,
    required this.onTap,
    this.trailing,
    this.isLink = true,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);

    return Semantics(
      link: isLink,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
              child: Row(
                spacing: 16,
                children: [
                  if (iconData != null)
                    Container(
                      width: 36,
                      height: 36,
                      decoration: ShapeDecoration(
                        color: palette.tint,
                        shape: const RoundedSuperellipseBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      child: Icon(iconData, size: 22, color: palette.heading),
                    ),
                  Expanded(
                    child: TranslatedText(
                      labelTranslationKey,
                      style: palette.body(16),
                    ),
                  ),
                  trailing ?? Icon(Icons.chevron_right, color: palette.faint),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
