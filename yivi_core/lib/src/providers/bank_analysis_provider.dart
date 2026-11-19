import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";

import "../models/bank_analysis.dart";
import "../models/session.dart";
import "./bank_accounts_provider.dart";

/// The names of the cards an analysis can add, from the issuer.
final analysisDefinitionsProvider = FutureProvider<AnalysisDefinitions>(
  (ref) => ref.watch(bankAccountsApiProvider).getAnalysisDefinitions(),
);

enum BankAnalysisStage {
  /// Nothing happened yet: the user is told what the analysis does.
  intro,

  /// The transactions are being categorized.
  analysing,

  /// The result is there, for the user to choose what to add.
  review,

  /// The analysis did not work; see [BankAnalysisState.error].
  failed,
}

enum BankAnalysisFailure { noTransactions, rateLimit, timeout, other }

class BankAnalysisState {
  final BankAnalysisStage stage;
  final String job;
  final List<AnalysisCredentialGroup> groups;

  /// The kinds of cards the user wants to add.
  final Set<String> selected;
  final BankAnalysisFailure? error;

  /// Whether the chosen cards are being prepared for the wallet.
  final bool issuing;

  const BankAnalysisState({
    this.stage = BankAnalysisStage.intro,
    this.job = "",
    this.groups = const [],
    this.selected = const {},
    this.error,
    this.issuing = false,
  });

  BankAnalysisState copyWith({Set<String>? selected, bool? issuing}) =>
      BankAnalysisState(
        stage: stage,
        job: job,
        groups: groups,
        selected: selected ?? this.selected,
        error: error,
        issuing: issuing ?? this.issuing,
      );
}

/// How often the issuer is asked whether the analysis is done, and for how
/// long.
const bankAnalysisPollInterval = Duration(seconds: 2);
const bankAnalysisTimeout = Duration(minutes: 5);

/// The analysis of one bank connection, by its consent id: from starting it
/// to handing the chosen cards to the wallet.
final bankAnalysisProvider = NotifierProvider.autoDispose
    .family<BankAnalysisNotifier, BankAnalysisState, String>(
      BankAnalysisNotifier.new,
    );

class BankAnalysisNotifier extends Notifier<BankAnalysisState> {
  BankAnalysisNotifier(this.consentId);

  final String consentId;

  @override
  BankAnalysisState build() => const BankAnalysisState();

  void _fail(Object error) {
    if (!ref.mounted) return;
    state = BankAnalysisState(
      stage: BankAnalysisStage.failed,
      error: switch (error) {
        BankAnalysisFailure() => error,
        BankAccountsRateLimitError() => BankAnalysisFailure.rateLimit,
        TimeoutException() => BankAnalysisFailure.timeout,
        _ => BankAnalysisFailure.other,
      },
    );
  }

  /// Starts the analysis and waits for its result.
  Future<void> start() async {
    if (state.stage == BankAnalysisStage.analysing) return;
    state = const BankAnalysisState(stage: BankAnalysisStage.analysing);
    final api = ref.read(bankAccountsApiProvider);
    try {
      // the names are needed to show the result; fetch them meanwhile
      final definitions = ref.read(analysisDefinitionsProvider.future);
      var analysis = await api.startAnalysis(consentId);
      final deadline = DateTime.now().add(bankAnalysisTimeout);

      while (analysis.status == BankAnalysisStatus.categorizing) {
        if (DateTime.now().isAfter(deadline)) throw TimeoutException(null);
        await Future<void>.delayed(bankAnalysisPollInterval);
        // the user left the screen
        if (!ref.mounted) return;
        analysis = await api.getAnalysis(consentId, job: analysis.job);
      }
      if (!ref.mounted) return;

      if (analysis.status == BankAnalysisStatus.failed) {
        throw analysis.error == "error:no-transactions"
            ? BankAnalysisFailure.noTransactions
            : BankAnalysisFailure.other;
      }
      final groups = groupAnalysisCredentials(
        analysis.credentials,
        await definitions,
      );
      if (!ref.mounted) return;
      state = BankAnalysisState(
        stage: BankAnalysisStage.review,
        job: analysis.job,
        groups: groups,
        // by default everything that has something to tell
        selected: {
          for (final group in groups)
            if (!group.isEmpty) group.key,
        },
      );
    } on Object catch (e) {
      _fail(e);
    }
  }

  void toggle(String key) {
    final selected = {...state.selected};
    if (!selected.remove(key)) selected.add(key);
    state = state.copyWith(selected: selected);
  }

  /// Has the chosen cards made ready and completes with the session in which
  /// the wallet receives them, or with null when that did not work.
  Future<SessionPointer?> issue() async {
    if (state.issuing || state.selected.isEmpty) return null;
    state = state.copyWith(issuing: true);
    try {
      return await ref
          .read(bankAccountsApiProvider)
          .issueAnalysis(
            consentId,
            job: state.job,
            credentials: state.selected.toList(),
          );
    } on Object {
      return null;
    } finally {
      if (ref.mounted) state = state.copyWith(issuing: false);
    }
  }
}
