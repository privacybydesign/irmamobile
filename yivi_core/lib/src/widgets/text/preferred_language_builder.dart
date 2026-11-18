import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../providers/preferences_provider.dart";

typedef PreferredLocaleBuilderType =
    Widget Function(BuildContext context, Locale? preferredLocale);

class PreferredLocaleBuilder extends ConsumerWidget {
  final PreferredLocaleBuilderType builder;

  const PreferredLocaleBuilder({required this.builder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferredLanguageCode = ref.watch(preferredLanguageCodeProvider);
    final preferredLocale = preferredLanguageCode.isEmpty
        ? null
        : Locale(preferredLanguageCode);
    return builder(context, preferredLocale);
  }
}
