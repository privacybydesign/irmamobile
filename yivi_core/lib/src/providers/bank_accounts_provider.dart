import "dart:async";
import "dart:convert";
import "dart:math";

import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_web_auth_2/flutter_web_auth_2.dart";
import "package:http/http.dart" as http;

import "../models/bank_account.dart";
import "../models/bank_analysis.dart";
import "../models/session.dart";
import "./data_tab_section_provider.dart";
import "./preferences_provider.dart";
import "./provider_helpers.dart" as helpers;

/// The PSD2 issuer, which talks to the account information service for the
/// app. It holds the credentials of that service and keeps no bank data
/// itself; the app holds the consent ids.
///
/// Override it for a build with `--dart-define=PSD2_ISSUER_URL=...`, e.g. to
/// use an issuer running on the development machine.
final psd2IssuerUrlProvider = NotifierProvider(
  () => helpers.ValueNotifier(
    const String.fromEnvironment(
      "PSD2_ISSUER_URL",
      defaultValue: "https://psd2-issuer.staging.yivi.app",
    ),
  ),
);

final bankAccountsApiProvider = Provider<BankAccountsApi>(
  (ref) => DefaultBankAccountsApi(host: ref.watch(psd2IssuerUrlProvider)),
);

/// Opens [url] in a browser and completes with the URL the browser was
/// redirected to once that URL has the scheme [callbackUrlScheme], or with
/// null when the user closed the browser.
typedef BankConsentBrowser =
    Future<String?> Function({
      required String url,
      required String callbackUrlScheme,
    });

final bankConsentBrowserProvider = Provider<BankConsentBrowser>(
  (ref) => _authenticateInBrowser,
);

Future<String?> _authenticateInBrowser({
  required String url,
  required String callbackUrlScheme,
}) async {
  try {
    return await FlutterWebAuth2.authenticate(
      url: url,
      callbackUrlScheme: callbackUrlScheme,
    );
  } on PlatformException catch (e) {
    if (e.code == "CANCELED") return null;
    rethrow;
  }
}

// =============================================================================

sealed class BankAccountsError implements Exception {}

/// The consent is unknown to the account information service: it expired or
/// was removed.
class BankConsentNotFoundError extends BankAccountsError {}

class BankAccountsRateLimitError extends BankAccountsError {}

/// The bank reported that connecting failed, or the redirect back to the app
/// was not the answer to our request.
class BankConnectFailedError extends BankAccountsError {
  final String details;
  BankConnectFailedError(this.details);

  @override
  String toString() => "connecting the bank failed: $details";
}

class BankAccountsServerError extends BankAccountsError {
  final int statusCode;
  final String body;
  BankAccountsServerError(this.statusCode, this.body);

  @override
  String toString() => "PSD2 issuer answered $statusCode: $body";
}

class BankConnectRequest {
  /// The page where the user chooses and logs in at their bank.
  final String url;

  /// Where the browser is sent when the user is done.
  final String redirectUri;

  const BankConnectRequest({required this.url, required this.redirectUri});
}

abstract class BankAccountsApi {
  /// The banks that can be connected.
  Future<List<Bank>> getBanks();

  /// Starts connecting a bank. With [bank], the key of one of [getBanks],
  /// the user is taken to that bank without having to choose it again.
  Future<BankConnectRequest> connect({required String state, String? bank});

  /// Completes with a [BankConnectionStatus.gone] connection when the consent
  /// no longer exists.
  Future<BankConnection> getConnection(String consentId);

  /// The transactions of the last [days] days of one account, newest first.
  Future<List<BankTransaction>> getTransactions(
    String consentId, {
    required String accountId,
    int days = 90,
  });

  /// Asks for fresh data from the bank. The result shows up later, as a newer
  /// [BankConnection.updatedAt].
  Future<void> refresh(String consentId);

  /// Removes the consent, and with it the bank data, at the account
  /// information service.
  Future<void> delete(String consentId);

  /// The names of the cards an analysis can add to the wallet.
  Future<AnalysisDefinitions> getAnalysisDefinitions();

  /// Starts analysing the transactions of a bank connection.
  Future<BankAnalysis> startAnalysis(String consentId);

  /// How far the analysis [job] is and, once it is done, its result.
  Future<BankAnalysis> getAnalysis(String consentId, {required String job});

  /// Has the cards of the kinds in [credentials] made ready, and starts the
  /// session in which the wallet receives them.
  Future<SessionPointer> issueAnalysis(
    String consentId, {
    required String job,
    required List<String> credentials,
  });
}

class DefaultBankAccountsApi implements BankAccountsApi {
  final String host;
  final http.Client _client;

  DefaultBankAccountsApi({required this.host, http.Client? client})
    : _client = client ?? http.Client();

  // The consent id gives access to the accounts, so it travels as a bearer
  // token and never in the URL.
  Map<String, String> _auth(String consentId) => {
    "Authorization": "Bearer $consentId",
  };

  Never _fail(http.Response response) {
    throw switch (response.statusCode) {
      404 => BankConsentNotFoundError(),
      429 => BankAccountsRateLimitError(),
      _ => BankAccountsServerError(response.statusCode, response.body),
    };
  }

  @override
  Future<List<Bank>> getBanks() async {
    final response = await _client.get(Uri.parse("$host/api/accounts/banks"));
    if (response.statusCode != 200) _fail(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return [
      for (final bank in json["banks"] as List<dynamic>? ?? const [])
        Bank.fromJson(bank as Map<String, dynamic>),
    ];
  }

  @override
  Future<BankConnectRequest> connect({
    required String state,
    String? bank,
  }) async {
    final response = await _client.post(
      Uri.parse("$host/api/accounts/connect"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"state": state, "bank": ?bank}),
    );
    if (response.statusCode != 200) _fail(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return BankConnectRequest(
      url: json["url"] as String,
      redirectUri: json["redirect_uri"] as String,
    );
  }

  @override
  Future<BankConnection> getConnection(String consentId) async {
    final response = await _client.get(
      Uri.parse("$host/api/accounts"),
      headers: _auth(consentId),
    );
    if (response.statusCode == 404) return BankConnection.gone(consentId);
    if (response.statusCode != 200) _fail(response);
    return BankConnection.fromJson(
      consentId,
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<List<BankTransaction>> getTransactions(
    String consentId, {
    required String accountId,
    int days = 90,
  }) async {
    final uri = Uri.parse("$host/api/accounts/transactions").replace(
      queryParameters: {"account_id": accountId, "days": days.toString()},
    );
    final response = await _client.get(uri, headers: _auth(consentId));
    if (response.statusCode != 200) _fail(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return [
      for (final tx in json["transactions"] as List<dynamic>? ?? const [])
        BankTransaction.fromJson(tx as Map<String, dynamic>),
    ];
  }

  @override
  @override
  Future<void> refresh(String consentId) async {
    final response = await _client.post(
      Uri.parse("$host/api/accounts/refresh"),
      headers: _auth(consentId),
    );
    if (response.statusCode != 202) _fail(response);
  }

  @override
  Future<void> delete(String consentId) async {
    final response = await _client.delete(
      Uri.parse("$host/api/accounts"),
      headers: _auth(consentId),
    );
    if (response.statusCode != 204) _fail(response);
  }

  @override
  Future<AnalysisDefinitions> getAnalysisDefinitions() =>
      _getAnalysisDefinitions();

  @override
  Future<BankAnalysis> startAnalysis(String consentId) =>
      _startAnalysis(consentId);

  @override
  Future<BankAnalysis> getAnalysis(String consentId, {required String job}) =>
      _getAnalysis(consentId, job);

  @override
  Future<SessionPointer> issueAnalysis(
    String consentId, {
    required String job,
    required List<String> credentials,
  }) => _issueAnalysis(consentId, job, credentials);
}

extension _Analysis on DefaultBankAccountsApi {
  Future<AnalysisDefinitions> _getAnalysisDefinitions() async {
    final response = await _client.get(Uri.parse("$host/api/definitions"));
    if (response.statusCode != 200) _fail(response);
    return AnalysisDefinitions.fromJson(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
    );
  }

  Future<BankAnalysis> _startAnalysis(String consentId) async {
    final response = await _client.post(
      Uri.parse("$host/api/accounts/analysis"),
      headers: _auth(consentId),
    );
    if (response.statusCode != 200) _fail(response);
    return BankAnalysis.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<BankAnalysis> _getAnalysis(String consentId, String job) async {
    final response = await _client.get(
      Uri.parse(
        "$host/api/accounts/analysis",
      ).replace(queryParameters: {"job": job}),
      headers: _auth(consentId),
    );
    if (response.statusCode != 200) _fail(response);
    return BankAnalysis.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<SessionPointer> _issueAnalysis(
    String consentId,
    String job,
    List<String> credentials,
  ) async {
    final response = await _client.post(
      Uri.parse("$host/api/accounts/analysis/issue"),
      headers: {..._auth(consentId), "Content-Type": "application/json"},
      body: jsonEncode({"job": job, "credentials": credentials}),
    );
    if (response.statusCode != 200) _fail(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;

    // the issuer signed what is to be issued; the IRMA server starts the
    // session for it
    final session = await _client.post(
      Uri.parse("${json["irma_server_url"]}/session"),
      body: json["jwt"] as String,
    );
    if (session.statusCode != 200) _fail(session);
    final pointer = SessionPointer.fromJson(
      (jsonDecode(session.body) as Map<String, dynamic>)["sessionPtr"]
          as Map<String, dynamic>,
    );
    // the session started in this app, so it continues here
    pointer.continueOnSecondDevice = true;
    return pointer;
  }
}

// =============================================================================

/// The consent ids of the connected banks, kept on this device only.
final bankConsentIdsProvider = NotifierProvider(BankConsentIds.new);

class BankConsentIds extends Notifier<List<String>> {
  @override
  List<String> build() => ref.watch(preferencesProvider).getBankConsentIds();

  Future<void> _store(List<String> consentIds) async {
    await ref.read(preferencesProvider).setBankConsentIds(consentIds);
    state = consentIds;
  }

  Future<void> add(String consentId) async {
    if (state.contains(consentId)) return;
    await _store([...state, consentId]);
  }

  Future<void> remove(String consentId) =>
      _store(state.where((id) => id != consentId).toList());
}

/// Accounts the user removed while their bank connection is still in use for
/// other accounts, as `consentId/accountId`.
final hiddenBankAccountsProvider = NotifierProvider(HiddenBankAccounts.new);

class HiddenBankAccounts extends Notifier<Set<String>> {
  static String key(String consentId, String accountId) =>
      "$consentId/$accountId";

  @override
  Set<String> build() =>
      ref.watch(preferencesProvider).getHiddenBankAccounts().toSet();

  Future<void> _store(Set<String> accounts) async {
    await ref
        .read(preferencesProvider)
        .setHiddenBankAccounts(accounts.toList());
    state = accounts;
  }

  Future<void> hide(String consentId, String accountId) =>
      _store({...state, key(consentId, accountId)});

  /// Forgets the hidden accounts of a connection that is gone.
  Future<void> forgetConnection(String consentId) =>
      _store(state.where((k) => !k.startsWith("$consentId/")).toSet());
}

/// The connections for which the user asked for fresh data, with the time the
/// data was last updated when they asked. An entry goes away once newer data
/// arrived, or after [bankRefreshTimeout].
final requestedBankRefreshesProvider = NotifierProvider(
  RequestedBankRefreshes.new,
);

const bankRefreshTimeout = Duration(seconds: 90);

class RequestedBankRefresh {
  final DateTime? updatedAt;
  final DateTime requestedAt;
  const RequestedBankRefresh({
    required this.updatedAt,
    required this.requestedAt,
  });
}

class RequestedBankRefreshes
    extends Notifier<Map<String, RequestedBankRefresh>> {
  @override
  Map<String, RequestedBankRefresh> build() => const {};

  void add(String consentId, DateTime? updatedAt) => state = {
    ...state,
    consentId: RequestedBankRefresh(
      updatedAt: updatedAt,
      requestedAt: DateTime.now(),
    ),
  };

  void remove(Iterable<String> consentIds) {
    final done = consentIds.toSet();
    if (done.isEmpty) return;
    state = {
      for (final entry in state.entries)
        if (!done.contains(entry.key)) entry.key: entry.value,
    };
  }
}

/// The banks the user can choose from when adding an account.
final banksProvider = FutureProvider.autoDispose<List<Bank>>(
  (ref) => ref.watch(bankAccountsApiProvider).getBanks(),
);

/// Shows every account once. Connecting a bank again gives a new connection
/// with the same accounts; the newer connection is valid longest, so it is
/// the one that keeps them. [connections] are in the order they were made.
///
/// Returns the connections to show and the ids of the connections that are
/// superseded: older ones of which a newer connection has every account.
({List<BankConnection> connections, List<String> superseded})
deduplicateBankConnections(List<BankConnection> connections) {
  final seen = <String>{};
  final superseded = <String>[];
  final result = <BankConnection>[];

  for (final connection in connections.reversed) {
    if (connection.status != BankConnectionStatus.ready ||
        connection.accounts.isEmpty) {
      result.add(connection);
      continue;
    }
    final unique = <BankAccount>[];
    for (final account in connection.accounts) {
      // without an account number there is nothing to recognize it by
      final number = account.number.replaceAll(" ", "").toUpperCase();
      if (number.isEmpty || seen.add("${connection.bank}/$number")) {
        unique.add(account);
      }
    }
    if (unique.isEmpty) {
      superseded.add(connection.consentId);
    } else {
      result.add(connection.copyWith(accounts: unique));
    }
  }
  return (connections: result.reversed.toList(), superseded: superseded);
}

/// How often the connections are fetched again while one of them is still
/// waiting for its bank data.
const bankConnectionsPollInterval = Duration(seconds: 3);

/// The connected banks with the accounts to show, read from the account
/// information service each time: nothing but the consent ids is kept on the
/// device.
final bankConnectionsProvider =
    FutureProvider.autoDispose<List<BankConnection>>((ref) async {
      final api = ref.watch(bankAccountsApiProvider);
      final consentIds = ref.watch(bankConsentIdsProvider);
      final hidden = ref.watch(hiddenBankAccountsProvider);
      final requested = ref.watch(requestedBankRefreshesProvider);
      final fetched = await Future.wait(consentIds.map(api.getConnection));

      // a requested refresh is done once newer data arrived
      final now = DateTime.now();
      final finished = [
        for (final c in fetched)
          if (requested[c.consentId] case final request?)
            if (c.updatedAt != request.updatedAt ||
                c.status != BankConnectionStatus.ready ||
                now.difference(request.requestedAt) > bankRefreshTimeout)
              c.consentId,
      ];
      if (finished.isNotEmpty) {
        final refreshes = ref.read(requestedBankRefreshesProvider.notifier);
        Future.microtask(() => refreshes.remove(finished));
      }

      final visible = [
        for (final c in fetched)
          c.copyWith(
            refreshing:
                c.refreshing ||
                (requested.containsKey(c.consentId) &&
                    !finished.contains(c.consentId)),
            accounts: [
              for (final account in c.accounts)
                if (!hidden.contains(
                  HiddenBankAccounts.key(c.consentId, account.id),
                ))
                  account,
            ],
          ),
      ];

      // an account that was connected twice is shown once, and a connection
      // that a newer one replaced is ended
      final (:connections, :superseded) = deduplicateBankConnections(visible);
      if (superseded.isNotEmpty) {
        final connector = ref.read(bankConnectorProvider);
        Future.microtask(() => connector.removeSuperseded(superseded));
      }

      if (connections.any(
        (c) => c.status == BankConnectionStatus.pending || c.refreshing,
      )) {
        final timer = Timer(bankConnectionsPollInterval, ref.invalidateSelf);
        ref.onDispose(timer.cancel);
      }
      return connections;
    });

class BankTransactionsQuery {
  final String consentId;
  final String accountId;

  const BankTransactionsQuery({
    required this.consentId,
    required this.accountId,
  });

  @override
  bool operator ==(Object other) =>
      other is BankTransactionsQuery &&
      other.consentId == consentId &&
      other.accountId == accountId;

  @override
  int get hashCode => Object.hash(consentId, accountId);
}

final bankTransactionsProvider = FutureProvider.autoDispose
    .family<List<BankTransaction>, BankTransactionsQuery>(
      (ref, query) => ref
          .watch(bankAccountsApiProvider)
          .getTransactions(query.consentId, accountId: query.accountId),
    );

// =============================================================================

final bankConnectorProvider = Provider(BankConnector.new);

/// Connects, refreshes and removes bank connections and their accounts.
class BankConnector {
  BankConnector(this._ref);

  final Ref _ref;

  static const _stateAlphabet =
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

  static String _newState() {
    final random = Random.secure();
    return List.generate(
      32,
      (_) => _stateAlphabet[random.nextInt(_stateAlphabet.length)],
    ).join();
  }

  /// Lets the user connect a bank in the browser: [bank] when given, or else
  /// one they choose there. Completes with false when the user closed the
  /// browser without finishing.
  Future<bool> connect({String? bank}) async {
    final api = _ref.read(bankAccountsApiProvider);
    final state = _newState();
    final request = await api.connect(state: state, bank: bank);

    final result = await _ref.read(bankConsentBrowserProvider)(
      url: request.url,
      callbackUrlScheme: Uri.parse(request.redirectUri).scheme,
    );
    if (result == null) return false;

    final consentId = consentIdFromRedirect(result, expectedState: state);
    await _ref.read(bankConsentIdsProvider.notifier).add(consentId);
    // coming back from the browser the user should see the new account,
    // also when the home screen was built anew in the meantime
    _ref.read(dataTabSectionProvider.notifier).set(DataTabSection.accounts);
    return true;
  }

  /// Asks for fresh data from the bank. A bank connection is refreshed as a
  /// whole: all its accounts get the new data.
  Future<void> refresh(BankConnection connection) async {
    await _ref.read(bankAccountsApiProvider).refresh(connection.consentId);
    _ref
        .read(requestedBankRefreshesProvider.notifier)
        .add(connection.consentId, connection.updatedAt);
  }

  /// Whether removing [account] ends the connection with the bank, because
  /// it is the last account of [connection] that is shown.
  static bool isLastAccount(BankConnection connection, BankAccount account) =>
      connection.accounts.every((a) => a.id == account.id);

  /// Removes one account. A bank connection can only be ended as a whole, so
  /// the account is hidden while other accounts of the connection are shown,
  /// and the connection is ended with the last account.
  Future<void> removeAccount(
    BankConnection connection,
    BankAccount account,
  ) async {
    if (isLastAccount(connection, account)) {
      await removeConnection(connection.consentId);
    } else {
      await _ref
          .read(hiddenBankAccountsProvider.notifier)
          .hide(connection.consentId, account.id);
    }
  }

  final _removing = <String>{};

  /// Ends connections that a newer connection replaced. This happens in the
  /// background: when it fails, it is tried again the next time the accounts
  /// are loaded.
  Future<void> removeSuperseded(List<String> consentIds) async {
    for (final consentId in consentIds) {
      if (!_removing.add(consentId)) continue;
      try {
        await removeConnection(consentId);
      } on Object {
        // tried again later
      } finally {
        _removing.remove(consentId);
      }
    }
  }

  /// Ends the connection at the account information service and then forgets
  /// it on this device. When the service can't be reached the connection is
  /// kept, so the bank data is never left behind without a way to remove it.
  Future<void> removeConnection(String consentId) async {
    try {
      await _ref.read(bankAccountsApiProvider).delete(consentId);
    } on BankConsentNotFoundError {
      // already gone
    }
    await _ref.read(bankConsentIdsProvider.notifier).remove(consentId);
    await _ref
        .read(hiddenBankAccountsProvider.notifier)
        .forgetConnection(consentId);
  }
}

/// Reads the consent id from the URL the browser was redirected to, after
/// checking that the redirect answers the request we made.
String consentIdFromRedirect(String url, {required String expectedState}) {
  final params = Uri.parse(url).queryParameters;
  if (params["state"] != expectedState) {
    throw BankConnectFailedError("state mismatch");
  }
  final error = params["error"];
  if (error != null) {
    throw BankConnectFailedError(params["error_type"] ?? error);
  }
  final consentId = params["consent_id"];
  if (consentId == null || consentId.isEmpty) {
    throw BankConnectFailedError("no consent id");
  }
  return consentId;
}
