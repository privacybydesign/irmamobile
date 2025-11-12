import 'package:flutter/material.dart';

import '../providers/irma_repository_provider.dart';

typedef PreferredLocaleBuilderType = Widget Function(
  BuildContext context,
  Locale? preferredLocale,
);

class PreferredLocaleBuilder extends StatelessWidget {
  final PreferredLocaleBuilderType builder;

  const PreferredLocaleBuilder({
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final prefs = IrmaRepositoryProvider.of(context).preferences;

    return StreamBuilder(
      stream: prefs.getPreferredLanguageCode(),
      builder: (context, AsyncSnapshot<String?> snapshot) {
        if (!snapshot.hasData) return Container();
        final preferredLanguageCode = snapshot.data!;
        final preferredLocale = preferredLanguageCode.isEmpty ? null : Locale(preferredLanguageCode);

        return builder(
          context,
          preferredLocale,
        );
      },
    );
  }
}
