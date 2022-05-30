import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../sentry/sentry.dart';
import '../../../theme/theme.dart';
import '../../../widgets/irma_card.dart';
import '../../../widgets/irma_repository_provider.dart';
import '../../../widgets/translated_text.dart';

class IrmaInfoCard extends StatelessWidget {
  final String titleKey;
  final String bodyKey;
  final String? linkKey;
  final Widget? avatar;

  const IrmaInfoCard({
    required this.titleKey,
    required this.bodyKey,
    this.avatar,
    this.linkKey,
  });

  void _tryLaunchLink(BuildContext context) {
    if (linkKey != null) {
      try {
        IrmaRepositoryProvider.of(context).openURL(
          FlutterI18n.translate(context, linkKey!),
        );
      } catch (e, stacktrace) {
        reportError(e, stacktrace);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return IrmaCard(
      onTap: () => _tryLaunchLink(context),
      child: Row(
        children: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: theme.tinySpacing),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Container(
              padding: EdgeInsets.all(theme.smallSpacing),
              height: 62,
              width: 62,
              child: avatar,
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(theme.smallSpacing),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TranslatedText(
                    titleKey,
                    style: theme.themeData.textTheme.caption!.copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: theme.smallSpacing),
                  Flexible(
                    child: TranslatedText(
                      bodyKey,
                      style: theme.themeData.textTheme.caption,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.grey.shade700,
          ),
        ],
      ),
    );
  }
}
