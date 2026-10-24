import "package:cupertino_ui/cupertino_ui.dart";
import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";
import "package:share_plus/share_plus.dart";

import "../../../providers/irma_repository_provider.dart";
import "../../../sentry/sentry.dart";
import "../../../theme/theme.dart";
import "../../../theme/yivi_palette.dart";
import "../../../widgets/link.dart";
import "../../../widgets/translated_text.dart";

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
      onTap: () => openSupportMail(context),
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

  /// Whether the detail pane shows this page.
  final bool selected;

  const InternalLinkTile({
    super.key,
    this.iconData,
    required this.labelTranslationKey,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tile(
      isLink: false,
      iconData: iconData,
      labelTranslationKey: labelTranslationKey,
      onTap: onTap,
      selected: selected,
    );
  }
}

class ToggleTile extends StatelessWidget {
  final IconData? iconData;
  final String labelTranslationKey;

  /// Grey text under the label that explains the setting.
  final String? subtitleTranslationKey;
  final void Function(bool) onChanged;
  final Stream<bool> stream;

  /// Extra space at the start, for a setting that belongs to the one above.
  final double indent;

  /// When false the row is greyed out and ignores taps.
  final bool enabled;

  const ToggleTile({
    super.key,
    this.iconData,
    required this.labelTranslationKey,
    this.subtitleTranslationKey,
    required this.onChanged,
    required this.stream,
    this.indent = 0,
    this.enabled = true,
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
            subtitleTranslationKey: subtitleTranslationKey,
            indent: indent,
            enabled: enabled,
            // Tapping anywhere on the row toggles the switch.
            onTap: () => toggle(!value),
            // The switch handles its own taps/drags too: a disabled
            // (onChanged: null) CupertinoSwitch swallows the gesture before it
            // reaches the Tile's onTap, so it must stay interactive.
            trailing: CupertinoSwitch(
              value: value,
              onChanged: toggle,
              activeTrackColor: theme.primary,
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

  /// Grey text under the label.
  final String? subtitleTranslationKey;

  /// Grey text at the end of the row, before the chevron, e.g. the current
  /// language.
  final String? value;
  final Function() onTap;
  final Widget? trailing;
  final bool isLink;

  /// A destructive action: red label and a red icon square, no chevron.
  final bool danger;

  /// Extra space at the start, for a row that belongs to the one above.
  final double indent;

  /// When false the row is greyed out and ignores taps.
  final bool enabled;

  /// Whether the detail pane shows what this row opens: the row is tinted
  /// and its chevron blue.
  final bool selected;

  const Tile({
    super.key,
    this.iconData,
    required this.labelTranslationKey,
    this.subtitleTranslationKey,
    this.value,
    required this.onTap,
    this.trailing,
    this.isLink = true,
    this.danger = false,
    this.indent = 0,
    this.enabled = true,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final (Color squareFill, Color iconColor, Color labelColor) = danger
        ? (palette.errorSurface, palette.danger, palette.danger)
        // On the tinted row the icon square is white.
        : (
            selected ? palette.surface : palette.tint,
            palette.heading,
            palette.text,
          );

    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 60),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16 + indent, 12, 12, 12),
        child: Row(
          spacing: 16,
          children: [
            if (iconData != null)
              Container(
                width: 36,
                height: 36,
                decoration: ShapeDecoration(
                  color: squareFill,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                child: Icon(iconData, size: 22, color: iconColor),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TranslatedText(
                    labelTranslationKey,
                    style: palette
                        .body(
                          16,
                          weight: danger ? FontWeight.w600 : FontWeight.w400,
                        )
                        .copyWith(color: labelColor),
                  ),
                  if (subtitleTranslationKey != null)
                    TranslatedText(
                      subtitleTranslationKey!,
                      style: palette
                          .body(14)
                          .copyWith(
                            height: 20 / 14,
                            color: palette.secondaryText,
                          ),
                    ),
                ],
              ),
            ),
            if (value != null)
              Text(
                value!,
                style: palette.body(14).copyWith(color: palette.secondaryText),
              ),
            trailing ??
                (danger
                    ? const SizedBox.shrink()
                    : Icon(
                        Icons.chevron_right,
                        color: selected ? palette.link : palette.faint,
                      )),
          ],
        ),
      ),
    );

    return Semantics(
      link: isLink,
      enabled: enabled,
      selected: selected,
      child: Material(
        color: selected ? palette.tint : Colors.transparent,
        child: IgnorePointer(
          ignoring: !enabled,
          child: Opacity(
            opacity: enabled ? 1 : 0.5,
            child: InkWell(onTap: onTap, child: row),
          ),
        ),
      ),
    );
  }
}
