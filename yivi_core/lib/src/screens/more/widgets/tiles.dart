import "package:cupertino_ui/cupertino_ui.dart";
import "package:share_plus/share_plus.dart";

import "../../../providers/irma_repository_provider.dart";
import "../../../sentry/sentry.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/haptics.dart";
import "../../../util/i18n.dart";
import "../../../widgets/icon_square.dart";
import "../../../widgets/link.dart";
import "../../../widgets/list_row.dart";

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
            text: context.tr(shareTextKey),
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
          repositoryOf(context).openURL(context.tr(urlLinkKey));
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
  final bool value;

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
    required this.value,
    this.indent = 0,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    void toggle(bool newValue) {
      Haptics.select();
      onChanged(newValue);
    }

    return Semantics(
      value: context.tr(
        value ? "switch.describe_state_on" : "switch.describe_state_off",
      ),
      hint: context.tr(
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
          activeTrackColor: YiviPalette.of(context).primary,
        ),
      ),
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
    final (Color squareFill, Color iconColor) = danger
        ? (palette.errorSurface, palette.danger)
        // On the tinted row the icon square is white; in dark one step
        // lighter than the row.
        : (
            selected
                ? (palette.isDark ? palette.raisedTint : palette.surface)
                : palette.tint,
            palette.heading,
          );

    return ListRow(
      title: context.tr(labelTranslationKey),
      subtitle: subtitleTranslationKey == null
          ? null
          : context.tr(subtitleTranslationKey!),
      leading: iconData == null
          ? null
          : IconSquare(
              icon: iconData!,
              fill: squareFill,
              ink: iconColor,
              iconSize: 22,
            ),
      value: value,
      trailingWidget: trailing,
      onTap: onTap,
      selected: selected,
      danger: danger,
      enabled: enabled,
      link: isLink,
      indent: indent,
      subtitleMaxLines: 99,
    );
  }
}
