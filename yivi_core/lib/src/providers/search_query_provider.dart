import "package:flutter_riverpod/flutter_riverpod.dart";

/// What is typed in a tab's search field. Kept outside the tab, so the
/// search is still there when the tab is built anew (coming back from a
/// card or an entry opened from the results).
class SearchQuery extends Notifier<String> {
  @override
  String build() => "";

  void set(String query) => state = query;
}

/// The search of the Data tab.
final dataSearchQueryProvider = NotifierProvider<SearchQuery, String>(
  SearchQuery.new,
);

/// The search of the Activity tab.
final activitySearchQueryProvider = NotifierProvider<SearchQuery, String>(
  SearchQuery.new,
);
