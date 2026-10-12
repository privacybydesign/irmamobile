import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../theme/theme.dart";
import "../../util/date_formatter.dart";
import "models/card_expiry_date.dart";
import "models/credential_card_status.dart";
import "models/status_line.dart";

/// The card's status line: how long the credential is valid and how often it
/// can still be shared, in one quiet centred line. An item that needs
/// attention (expiring soon, few shares left, expired) becomes a pill.
class YiviCredentialCardFooter extends StatelessWidget {
  final CardExpiryDate? expiryDate;
  final int? instanceCount;
  final ExpireState timeBasedExpireState;
  final ExpireState instanceBasedExpireState;

  final EdgeInsetsGeometry padding;

  const YiviCredentialCardFooter({
    required this.timeBasedExpireState,
    required this.instanceBasedExpireState,
    this.expiryDate,
    this.padding = EdgeInsets.zero,
    this.instanceCount,
  });

  @override
  Widget build(BuildContext context) {
    final lang = FlutterI18n.currentLocale(context)!.languageCode;
    final items = statusLineItems(
      expiryDate: expiryDate,
      instanceCount: instanceCount,
      timeState: timeBasedExpireState,
      instanceState: instanceBasedExpireState,
      formatDate: (d) => printableDate(d, lang),
    );
    final theme = IrmaTheme.of(context);

    return Padding(
      padding: padding,
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: theme.smallSpacing + theme.tinySpacing,
          runSpacing: theme.tinySpacing,
          children: [for (final item in items) _StatusItem(item)],
        ),
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final StatusLineItem item;

  const _StatusItem(this.item);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final text = item.pluralCount != null
        ? FlutterI18n.plural(context, item.translationKey, item.pluralCount!)
        : FlutterI18n.translate(
            context,
            item.translationKey,
            translationParams: item.params,
          );

    final (foreground, background) = switch (item.tone) {
      StatusTone.calm => (theme.neutralDark, null),
      StatusTone.warning => (theme.onWarningSurface, theme.warningSurface),
      StatusTone.error => (theme.error, theme.errorSurface),
    };

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: theme.tinySpacing,
      children: [
        Icon(
          item.kind == StatusKind.validity
              ? Icons.calendar_today_outlined
              : Icons.share_outlined,
          size: 13,
          color: foreground,
        ),
        Text(
          text,
          style: TextStyle(
            fontFamily: theme.secondaryFontFamily,
            fontSize: 12,
            fontWeight: background == null ? FontWeight.w400 : FontWeight.w600,
            color: foreground,
          ),
        ),
      ],
    );

    return Container(
      key: Key("status_line_${item.kind.name}"),
      padding: background == null
          ? EdgeInsets.zero
          : const EdgeInsets.fromLTRB(6, 2, 8, 2),
      decoration: background == null
          ? null
          : BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(999),
            ),
      child: content,
    );
  }
}
