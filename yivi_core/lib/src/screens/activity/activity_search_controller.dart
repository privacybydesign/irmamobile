import "dart:async";

import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../models/activity_query.dart";
import "../../providers/activity_providers.dart";
import "../../providers/irma_repository_provider.dart";
import "activity_kind_words.dart";
import "activity_options.dart";

/// The Activity tab's search.
@immutable
class ActivitySearch {
  /// A search is on. It starts when the field gets focus and ends on
  /// Cancel, or once nothing is typed or tagged any more after Enter; not
  /// when the field loses focus.
  final bool searching;

  /// Enter pressed: the field stays up in the bar with the typed words, the
  /// keyboard and the suggestions go, and the filter takes Cancel's place.
  /// Back in the field, it is typing again.
  final bool submitted;
  final String typed;

  /// The question asked before searching: Cancel goes back to it.
  final ActivityQuery before;

  /// The question being built while searching: the applied one at the
  /// start, a tag more with each pick. The log shows what it finds with
  /// the typed words.
  final ActivityQuery? draft;

  /// How many entries each suggestion would leave: those with none go.
  final Map<String, int> counts;

  /// One more with every question asked: the log jumps to the top, also
  /// when the question did not change (Cancel without a change).
  final int asks;

  const ActivitySearch({
    this.searching = false,
    this.submitted = false,
    this.typed = "",
    this.before = ActivityQuery.empty,
    this.draft,
    this.counts = const {},
    this.asks = 0,
  });

  /// Searching and not yet past Enter: Cancel, the suggestions, the live
  /// count.
  bool get typing => searching && !submitted;

  ActivitySearch copyWith({
    bool? searching,
    bool? submitted,
    String? typed,
    ActivityQuery? before,
    ActivityQuery? Function()? draft,
    Map<String, int>? counts,
    int? asks,
  }) => ActivitySearch(
    searching: searching ?? this.searching,
    submitted: submitted ?? this.submitted,
    typed: typed ?? this.typed,
    before: before ?? this.before,
    draft: draft == null ? this.draft : draft(),
    counts: counts ?? this.counts,
    asks: asks ?? this.asks,
  );
}

final activitySearchProvider =
    NotifierProvider.autoDispose<ActivitySearchController, ActivitySearch>(
      ActivitySearchController.new,
    );

/// What the Activity tab's search does. The field, its focus and the
/// scrolling stay with the tab, which follows this state.
class ActivitySearchController extends Notifier<ActivitySearch> {
  Timer? _liveDelay;
  Timer? _countDelay;
  late final _counter = ActivityOptionCounter(
    ref.read(activityLogClientProvider),
  );

  @override
  ActivitySearch build() {
    ref.onDispose(() {
      _liveDelay?.cancel();
      _countDelay?.cancel();
    });
    return const ActivitySearch();
  }

  ActivityQuery get _query => ref.read(activityLogProvider).filter;

  /// What the suggestions build on: the draft while searching.
  ActivityQuery get asked => state.draft ?? _query;

  /// Asks the log [query], and the log goes to the top.
  void ask(ActivityQuery query) {
    ref.read(activityLogProvider.notifier).setFilter(query);
    state = state.copyWith(asks: state.asks + 1);
  }

  void start(ActivityWords words) {
    state = state.copyWith(
      searching: true,
      submitted: false,
      before: _query,
      draft: () => _query,
    );
    _scheduleCounts(words);
  }

  /// The field got the focus: the search starts, or after Enter it is
  /// typing again.
  void focused(ActivityWords words) {
    if (!state.searching) {
      start(words);
    } else if (state.submitted) {
      state = state.copyWith(submitted: false);
      _scheduleCounts(words);
    }
  }

  /// Ends the search: the log keeps [keep], or (Cancel) goes back to the
  /// question asked before.
  void end({ActivityQuery? keep}) {
    _liveDelay?.cancel();
    final before = state.before;
    state = state.copyWith(
      searching: false,
      submitted: false,
      typed: "",
      draft: () => null,
    );
    ask(keep ?? before);
  }

  /// The log shows what the draft and the typed words find, a moment
  /// after typing stops (a tag at once).
  void _showLive(ActivityWords words, {bool now = false}) {
    _liveDelay?.cancel();
    void show() {
      if (!ref.mounted || !state.searching) return;
      ask(_withTyped(asked, state.typed, words));
    }

    if (now) {
      show();
    } else {
      _liveDelay = Timer(const Duration(milliseconds: 150), show);
    }
  }

  /// The draft with what is still typed as words to search.
  static ActivityQuery _withTyped(
    ActivityQuery q,
    String typed,
    ActivityWords words,
  ) {
    // "gedeeld met" asks for shared entries; the rest is searched.
    final (kinds, rest) = readKindWords(typed, words.kindPhrases());
    if (kinds.isNotEmpty) q = q.copyWith(kinds: {...q.kinds, ...kinds});
    final text = rest.trim();
    if (text.isEmpty) return q;
    final asked = q.text.trim();
    return q.copyWith(text: asked.isEmpty ? text : "$asked $text");
  }

  void type(String text, ActivityWords words) {
    state = state.copyWith(typed: text);
    _showLive(words);
    _scheduleCounts(words);
  }

  /// A suggestion: a tag more on the draft. The field empties, to add
  /// another.
  void pick(ActivityQuery query, ActivityWords words) {
    state = state.copyWith(draft: () => query, typed: "");
    _showLive(words, now: true);
    _scheduleCounts(words);
  }

  /// A tag's cross while searching: the draft without it. After Enter, with
  /// nothing left asked, the search ends.
  void changeDraft(ActivityQuery query, ActivityWords words) {
    if (state.submitted && query.isEmpty && state.typed.trim().isEmpty) {
      return end(keep: ActivityQuery.empty);
    }
    state = state.copyWith(draft: () => query);
    _showLive(words, now: true);
    _scheduleCounts(words);
  }

  /// Enter: the log shows what the draft and the typed words find, and the
  /// field stays with them; with nothing asked, the search ends.
  void submit(String text, ActivityWords words) {
    if (asked.isEmpty && text.trim().isEmpty) {
      return end(keep: ActivityQuery.empty);
    }
    _countDelay?.cancel();
    state = state.copyWith(typed: text, submitted: true);
    _showLive(words, now: true);
  }

  /// The field's clear button: after Enter, with no tags either, the search
  /// ends (true); otherwise it is typing again.
  bool cleared() {
    if (state.submitted && asked.isEmpty) {
      end(keep: ActivityQuery.empty);
      return true;
    }
    return false;
  }

  /// The filter sheet's question. While searching the typed words stay in
  /// the field, not in the draft.
  void applyFilter(ActivityQuery next, ActivityWords words) {
    if (!state.searching) return ask(next);
    final draft = next.copyWith(text: asked.text);
    if (draft.isEmpty && state.typed.trim().isEmpty) {
      return end(keep: ActivityQuery.empty);
    }
    state = state.copyWith(draft: () => draft);
    _showLive(words, now: true);
  }

  /// "Clear": nothing asked, and no search any more.
  void clearAll() => state.searching
      ? end(keep: ActivityQuery.empty)
      : ask(ActivityQuery.empty);

  /// Counts what each suggestion would leave, a moment after typing stops.
  void _scheduleCounts(ActivityWords words) {
    _countDelay?.cancel();
    _countDelay = Timer(const Duration(milliseconds: 150), () async {
      if (!ref.mounted || !state.searching) return;
      final options = activitySuggestions(
        asked: asked,
        typed: state.typed,
        cards: ref.read(activityCardRefsProvider),
        parties: ref.read(activityPartiesProvider).value ?? const [],
        words: words,
      ).flattened;
      final counts = await _counter.count({
        for (final o in options) o.key: o.query,
      });
      if (counts == null || !ref.mounted) return;
      state = state.copyWith(counts: counts);
    });
  }
}
