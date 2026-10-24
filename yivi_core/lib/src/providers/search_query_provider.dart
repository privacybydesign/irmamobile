import "package:flutter_riverpod/flutter_riverpod.dart";

import "provider_helpers.dart" as helpers;

// What is typed in a tab's search field. Kept outside the tab, so the
// search is still there when the tab is built anew (coming back from a card
// or an entry opened from the results).

/// The search of the Data tab.
final dataSearchQueryProvider =
    NotifierProvider<helpers.ValueNotifier<String>, String>(
      () => helpers.ValueNotifier(""),
    );

/// The search of the Activity tab.
final activitySearchQueryProvider =
    NotifierProvider<helpers.ValueNotifier<String>, String>(
      () => helpers.ValueNotifier(""),
    );
