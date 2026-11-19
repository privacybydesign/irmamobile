import "dart:convert";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:streaming_shared_preferences/streaming_shared_preferences.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/models/bank_account.dart";
import "package:yivi_core/src/models/bank_analysis.dart";
import "package:yivi_core/src/models/protocol.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/providers/bank_accounts_provider.dart";
import "package:yivi_core/src/providers/bank_analysis_provider.dart";
import "package:yivi_core/src/providers/data_tab_section_provider.dart";
import "package:yivi_core/src/providers/preferences_provider.dart";

const _host = "https://issuer.example";
const _consentId = "consent-123";

class _FakeApi implements BankAccountsApi {
  String? state;
  final deleted = <String>[];
  final refreshed = <String>[];
  Object? deleteError;
  List<BankAccount> accounts = const [];
  final accountsOf = <String, List<BankAccount>>{};
  DateTime? updatedAt;

  String? bank;

  @override
  Future<List<Bank>> getBanks() async => const [
    Bank(key: "ENSANDBOX", name: "Sandbox Bank"),
  ];

  @override
  Future<BankConnectRequest> connect({
    required String state,
    String? bank,
  }) async {
    this.bank = bank;
    this.state = state;
    return const BankConnectRequest(
      url: "https://app.enablenow.example/?client=x",
      redirectUri: "app.yivi.open://accounts",
    );
  }

  @override
  Future<BankConnection> getConnection(String consentId) async =>
      BankConnection(
        consentId: consentId,
        status: .ready,
        bank: "ENSANDBOX",
        updatedAt: updatedAt,
        accounts: accountsOf[consentId] ?? accounts,
      );

  @override
  Future<List<BankTransaction>> getTransactions(
    String consentId, {
    required String accountId,
    int days = 90,
  }) async => const [];

  @override
  Future<void> refresh(String consentId) async => refreshed.add(consentId);

  @override
  Future<void> delete(String consentId) async {
    if (deleteError case final error?) throw error;
    deleted.add(consentId);
  }

  /// The statuses the analysis goes through, one per call.
  var analysisSteps = <BankAnalysis>[];
  Object? analysisError;
  List<String>? issued;
  final asked = <String>[];

  @override
  Future<AnalysisDefinitions> getAnalysisDefinitions() async =>
      AnalysisDefinitions.fromJson(_definitions);

  @override
  Future<BankAnalysis> startAnalysis(String consentId) async {
    if (analysisError case final error?) throw error;
    asked.add("start");
    return analysisSteps.removeAt(0);
  }

  @override
  Future<BankAnalysis> getAnalysis(
    String consentId, {
    required String job,
  }) async {
    asked.add("status $job");
    return analysisSteps.removeAt(0);
  }

  @override
  Future<SessionPointer> issueAnalysis(
    String consentId, {
    required String job,
    required List<String> credentials,
  }) async {
    issued = credentials;
    return SessionPointer(
      u: "https://irma.example/session/abc",
      irmaqr: "issuing",
      protocol: Protocol.irma,
    );
  }
}

const _definitions = {
  "credentials": [
    {
      "key": "income",
      "e1_group": "income",
      "name": {"en": "Income", "nl": "Inkomen"},
      "description": {"en": "Salary and other income", "nl": "Salaris"},
      "attributes": [
        {
          "id": "salary",
          "e1": "income.salary",
          "name": {"en": "Salary", "nl": "Salaris"},
        },
        {
          "id": "other",
          "e1": "income.other",
          "name": {"en": "Other", "nl": "Overig"},
        },
      ],
    },
    {
      "key": "gambling",
      "e1_group": "gambling",
      "name": {"en": "Gambling", "nl": "Kansspelen"},
      "description": {"en": "Lotteries", "nl": "Loterijen"},
      "attributes": [
        {
          "id": "lottery",
          "e1": "gambling.lottery",
          "name": {"en": "Lottery", "nl": "Loterij"},
        },
      ],
    },
    {
      "key": "bankaccount",
      "name": {"en": "Bank account", "nl": "Bankrekening"},
      "description": {"en": "Your account", "nl": "Je rekening"},
      "attributes": [
        {
          "id": "iban",
          "name": {"en": "IBAN", "nl": "IBAN"},
        },
      ],
    },
  ],
};

const _analysisResult = BankAnalysis(
  status: .ready,
  job: "job-1",
  credentials: [
    AnalysisCredential(
      key: "income",
      attributes: {"months": "12", "salary": "3220", "other": "0"},
    ),
    AnalysisCredential(
      key: "gambling",
      attributes: {"months": "12", "lottery": "0"},
    ),
    AnalysisCredential(
      key: "bankaccount",
      attributes: {"iban": "NL11ENAB1234567890"},
    ),
    AnalysisCredential(
      key: "bankaccount",
      attributes: {"iban": "NL99ENAB0987654321"},
    ),
  ],
);

Future<ProviderContainer> _container(
  _FakeApi api, {
  required BankConsentBrowser browser,
}) async {
  SharedPreferences.setMockInitialValues({});
  // the instance is a singleton, so drop what an earlier test stored
  final streamingPreferences = await StreamingSharedPreferences.instance;
  await streamingPreferences.clear();
  final preferences = IrmaPreferences(
    streamingPreferences,
    mostRecentTermsUrlNl: "",
    mostRecentTermsUrlEn: "",
  );
  final container = ProviderContainer(
    overrides: [
      preferencesProvider.overrideWithValue(preferences),
      bankAccountsApiProvider.overrideWithValue(api),
      bankConsentBrowserProvider.overrideWithValue(browser),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("DefaultBankAccountsApi", () {
    test("sends the consent id as bearer token, never in the URL", () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return switch (request.url.path) {
          "/api/accounts" when request.method == "GET" => http.Response(
            jsonEncode({
              "status": "ready",
              "bank": "ABNAMRO",
              "expires_at": "2027-05-17T10:00:00Z",
              "accounts": [
                {
                  "id": "acc-1",
                  "iban": "NL91ABNA0417164300",
                  "holder": "J. Jansen",
                  "currency": "EUR",
                  "balance": {"amount": 1843.27, "currency": "EUR"},
                },
              ],
            }),
            200,
          ),
          "/api/accounts/transactions" => http.Response(
            jsonEncode({
              "transactions": [
                {
                  "id": "tx-1",
                  "account_id": "acc-1",
                  "date": "2026-11-01",
                  "amount": -12.5,
                  "currency": "EUR",
                  "counterpart": "Bakery",
                },
              ],
            }),
            200,
          ),
          "/api/accounts/refresh" => http.Response("", 202),
          "/api/accounts" => http.Response("", 204),
          _ => http.Response("unexpected", 500),
        };
      });
      final api = DefaultBankAccountsApi(host: _host, client: client);

      final connection = await api.getConnection(_consentId);
      expect(connection.status, BankConnectionStatus.ready);
      expect(connection.bank, "ABNAMRO");
      expect(connection.expiresAt, DateTime.utc(2027, 5, 17, 10));
      expect(connection.accounts.single.number, "NL91ABNA0417164300");
      expect(connection.accounts.single.balance!.amount, 1843.27);

      final transactions = await api.getTransactions(
        _consentId,
        accountId: "acc-1",
      );
      expect(transactions.single.title, "Bakery");
      expect(transactions.single.amount, -12.5);

      await api.refresh(_consentId);
      await api.delete(_consentId);

      expect(requests, hasLength(4));
      for (final request in requests) {
        expect(request.headers["Authorization"], "Bearer $_consentId");
        expect(request.url.toString(), isNot(contains(_consentId)));
      }
      expect(requests[1].url.queryParameters, {
        "account_id": "acc-1",
        "days": "90",
      });
    });

    test("a consent that no longer exists is a gone connection", () async {
      final api = DefaultBankAccountsApi(
        host: _host,
        client: MockClient(
          (_) async => http.Response("error:consent-not-found", 404),
        ),
      );
      final connection = await api.getConnection(_consentId);
      expect(connection.status, BankConnectionStatus.gone);
      expect(connection.consentId, _consentId);
    });

    test("maps error responses", () async {
      var status = 429;
      final api = DefaultBankAccountsApi(
        host: _host,
        client: MockClient((_) async => http.Response("error", status)),
      );
      await expectLater(
        api.refresh(_consentId),
        throwsA(isA<BankAccountsRateLimitError>()),
      );
      status = 502;
      await expectLater(
        api.getConnection(_consentId),
        throwsA(isA<BankAccountsServerError>()),
      );
      status = 404;
      await expectLater(
        api.delete(_consentId),
        throwsA(isA<BankConsentNotFoundError>()),
      );
    });
  });

  group("deduplicateBankConnections", () {
    BankConnection connection(String id, List<String> ibans, {String? bank}) =>
        BankConnection(
          consentId: id,
          status: .ready,
          bank: bank ?? "ENSANDBOX",
          accounts: [
            for (final iban in ibans) BankAccount(id: "$id-$iban", iban: iban),
          ],
        );

    test("an older connection keeps the accounts a newer one lacks", () {
      final result = deduplicateBankConnections([
        connection("old", ["NL01", "NL02"]),
        connection("new", ["NL02"]),
      ]);
      expect(result.superseded, isEmpty);
      expect(result.connections.map((c) => c.consentId), ["old", "new"]);
      expect(result.connections.first.accounts.single.iban, "NL01");
      expect(result.connections.last.accounts.single.iban, "NL02");
    });

    test("the same number at another bank is another account", () {
      final result = deduplicateBankConnections([
        connection("a", ["NL01"], bank: "INGBNL2A"),
        connection("b", ["NL01"]),
      ]);
      expect(result.superseded, isEmpty);
      expect(result.connections, hasLength(2));
    });

    test("connections that are not ready are left alone", () {
      const pending = BankConnection(consentId: "p", status: .pending);
      final result = deduplicateBankConnections([
        connection("old", ["NL01"]),
        pending,
      ]);
      expect(result.superseded, isEmpty);
      expect(result.connections, hasLength(2));
    });
  });

  group("BankAnalysisNotifier", () {
    Future<ProviderContainer> container(_FakeApi api) => _container(
      api,
      browser: ({required url, required callbackUrlScheme}) async => null,
    );

    test("analyses, lets the user choose and issues what was chosen", () async {
      final api = _FakeApi()
        ..analysisSteps = [
          const BankAnalysis(status: .categorizing, job: "job-1"),
          _analysisResult,
        ];
      final c = await container(api);
      final provider = bankAnalysisProvider(_consentId);
      c.listen(provider, (_, _) {});
      expect(c.read(provider).stage, BankAnalysisStage.intro);

      await c.read(provider.notifier).start();
      expect(api.asked, ["start", "status job-1"]);

      final state = c.read(provider);
      expect(state.stage, BankAnalysisStage.review);
      // grouped per kind: the two bank accounts are one choice
      expect(state.groups.map((g) => g.key), [
        "income",
        "gambling",
        "bankaccount",
      ]);
      expect(state.groups.last.credentials, hasLength(2));
      // amounts that are zero are left out
      final income = state.groups.first;
      expect(income.amountsOf(income.credentials.single).single.$2, 3220);
      // a card with only zeros is not chosen by default
      expect(state.selected, {"income", "bankaccount"});

      c.read(provider.notifier).toggle("bankaccount");
      c.read(provider.notifier).toggle("gambling");
      final pointer = await c.read(provider.notifier).issue();
      expect(pointer, isNotNull);
      expect(api.issued, unorderedEquals(["income", "gambling"]));
    });

    test("tells apart why an analysis failed", () async {
      final api = _FakeApi()
        ..analysisSteps = [
          const BankAnalysis(
            status: .failed,
            job: "job-1",
            error: "error:no-transactions",
          ),
        ];
      final c = await container(api);
      final provider = bankAnalysisProvider(_consentId);
      c.listen(provider, (_, _) {});

      await c.read(provider.notifier).start();
      expect(c.read(provider).stage, BankAnalysisStage.failed);
      expect(c.read(provider).error, BankAnalysisFailure.noTransactions);

      api.analysisError = BankAccountsRateLimitError();
      await c.read(provider.notifier).start();
      expect(c.read(provider).error, BankAnalysisFailure.rateLimit);

      // nothing to issue without a result
      expect(await c.read(provider.notifier).issue(), isNull);
      expect(api.issued, isNull);
    });
  });

  group("DefaultBankAccountsApi analysis", () {
    test("has the issuer sign and the IRMA server start the session", () async {
      final requests = <http.Request>[];
      final api = DefaultBankAccountsApi(
        host: _host,
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.toString() == "$_host/api/accounts/analysis/issue") {
            return http.Response(
              jsonEncode({
                "jwt": "signed.jwt.value",
                "irma_server_url": "https://irma.example",
              }),
              200,
            );
          }
          if (request.url.toString() == "https://irma.example/session") {
            return http.Response(
              jsonEncode({
                "sessionPtr": {
                  "u": "https://irma.example/irma/session/abc",
                  "irmaqr": "issuing",
                },
              }),
              200,
            );
          }
          return http.Response("unexpected ${request.url}", 500);
        }),
      );

      final pointer = await api.issueAnalysis(
        _consentId,
        job: "job-1",
        credentials: ["income"],
      );
      expect(pointer.u, "https://irma.example/irma/session/abc");
      // the session continues in this app
      expect(pointer.continueOnSecondDevice, isTrue);

      expect(requests.first.headers["Authorization"], "Bearer $_consentId");
      expect(jsonDecode(requests.first.body), {
        "job": "job-1",
        "credentials": ["income"],
      });
      // the IRMA server gets the signed request, and nothing about the consent
      expect(requests.last.body, "signed.jwt.value");
      expect(requests.last.headers.containsKey("Authorization"), isFalse);
    });
  });

  group("consentIdFromRedirect", () {
    test("returns the consent id when the state matches", () {
      expect(
        consentIdFromRedirect(
          "app.yivi.open://accounts?state=abc&consent_id=$_consentId",
          expectedState: "abc",
        ),
        _consentId,
      );
    });

    test("rejects a redirect that does not answer our request", () {
      for (final url in [
        "app.yivi.open://accounts?state=other&consent_id=$_consentId",
        "app.yivi.open://accounts?consent_id=$_consentId",
        "app.yivi.open://accounts?state=abc",
        "app.yivi.open://accounts?state=abc&error=1&error_type=denied&consent_id=$_consentId",
      ]) {
        expect(
          () => consentIdFromRedirect(url, expectedState: "abc"),
          throwsA(isA<BankConnectFailedError>()),
          reason: url,
        );
      }
    });
  });

  group("BankConnector", () {
    test("stores the consent id the browser comes back with", () async {
      final api = _FakeApi();
      String? openedScheme;
      final container = await _container(
        api,
        browser: ({required url, required callbackUrlScheme}) async {
          openedScheme = callbackUrlScheme;
          return "app.yivi.open://accounts?state=${api.state}&consent_id=$_consentId";
        },
      );

      expect(
        container.read(dataTabSectionProvider),
        DataTabSection.credentials,
      );
      expect(await container.read(bankConnectorProvider).connect(), isTrue);
      // the user lands on their accounts, not on their credentials
      expect(container.read(dataTabSectionProvider), DataTabSection.accounts);
      expect(openedScheme, "app.yivi.open");
      expect(api.state, matches(RegExp(r"^[A-Za-z0-9]{32}$")));
      expect(container.read(bankConsentIdsProvider), [_consentId]);
      expect(container.read(preferencesProvider).getBankConsentIds(), [
        _consentId,
      ]);

      final connections = await container.read(bankConnectionsProvider.future);
      expect(connections.single.consentId, _consentId);
    });

    test("stores nothing when the user closes the browser", () async {
      final container = await _container(
        _FakeApi(),
        browser: ({required url, required callbackUrlScheme}) async => null,
      );
      expect(await container.read(bankConnectorProvider).connect(), isFalse);
      expect(container.read(bankConsentIdsProvider), isEmpty);
    });

    test("stores nothing when the state does not match", () async {
      final container = await _container(
        _FakeApi(),
        browser: ({required url, required callbackUrlScheme}) async =>
            "app.yivi.open://accounts?state=forged&consent_id=$_consentId",
      );
      await expectLater(
        container.read(bankConnectorProvider).connect(),
        throwsA(isA<BankConnectFailedError>()),
      );
      expect(container.read(bankConsentIdsProvider), isEmpty);
    });

    test("removes the consent at the service before forgetting it", () async {
      final api = _FakeApi();
      final container = await _container(
        api,
        browser: ({required url, required callbackUrlScheme}) async => null,
      );
      final ids = container.read(bankConsentIdsProvider.notifier);
      await ids.add(_consentId);
      final connector = container.read(bankConnectorProvider);

      // unreachable service: keep the connection, so it can be removed later
      api.deleteError = BankAccountsServerError(502, "");
      await expectLater(
        connector.removeConnection(_consentId),
        throwsA(isA<BankAccountsServerError>()),
      );
      expect(container.read(bankConsentIdsProvider), [_consentId]);

      // already gone at the service: forget it
      api.deleteError = BankConsentNotFoundError();
      await connector.removeConnection(_consentId);
      expect(container.read(bankConsentIdsProvider), isEmpty);

      await ids.add(_consentId);
      api.deleteError = null;
      await connector.removeConnection(_consentId);
      expect(api.deleted, [_consentId]);
      expect(container.read(bankConsentIdsProvider), isEmpty);
    });

    test("removing an account hides it until it is the last one", () async {
      final api = _FakeApi()
        ..accounts = const [
          BankAccount(id: "acc-1", iban: "NL11ENAB1234567890"),
          BankAccount(id: "acc-2", iban: "NL99ENAB0987654321"),
        ];
      final container = await _container(
        api,
        browser: ({required url, required callbackUrlScheme}) async => null,
      );
      await container.read(bankConsentIdsProvider.notifier).add(_consentId);
      final connector = container.read(bankConnectorProvider);

      var connection = (await container.read(
        bankConnectionsProvider.future,
      )).single;
      expect(connection.accounts, hasLength(2));

      // the bank connection is still needed for the other account
      await connector.removeAccount(connection, connection.accounts.first);
      expect(api.deleted, isEmpty);
      connection = (await container.read(
        bankConnectionsProvider.future,
      )).single;
      expect(connection.accounts.single.id, "acc-2");
      expect(container.read(preferencesProvider).getHiddenBankAccounts(), [
        "$_consentId/acc-1",
      ]);

      // the last account takes the bank connection with it
      await connector.removeAccount(connection, connection.accounts.single);
      expect(api.deleted, [_consentId]);
      expect(container.read(bankConsentIdsProvider), isEmpty);
      expect(
        container.read(preferencesProvider).getHiddenBankAccounts(),
        isEmpty,
      );
    });

    test("passes the chosen bank on", () async {
      final api = _FakeApi();
      final container = await _container(
        api,
        browser: ({required url, required callbackUrlScheme}) async => null,
      );
      await container.read(bankConnectorProvider).connect(bank: "ENSANDBOX");
      expect(api.bank, "ENSANDBOX");
    });

    test("connecting a bank again replaces the older connection", () async {
      const john = BankAccount(id: "a", iban: "NL11ENAB1234567890");
      const jane = BankAccount(id: "b", iban: "NL99ENAB0987654321");
      final api = _FakeApi()
        ..accountsOf["old"] = const [john, jane]
        // the same accounts get new ids in a new connection
        ..accountsOf["new"] = const [
          BankAccount(id: "c", iban: "NL11ENAB1234567890"),
          BankAccount(id: "d", iban: "NL99 ENAB 0987 6543 21"),
        ];
      final container = await _container(
        api,
        browser: ({required url, required callbackUrlScheme}) async => null,
      );
      final ids = container.read(bankConsentIdsProvider.notifier);
      await ids.add("old");
      await ids.add("new");
      container.listen(bankConnectionsProvider, (_, _) {});

      final connections = await container.read(bankConnectionsProvider.future);
      expect(connections.single.consentId, "new");
      expect(connections.single.accounts.map((a) => a.id), ["c", "d"]);

      // the older connection is ended in the background
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(api.deleted, ["old"]);
      expect(container.read(bankConsentIdsProvider), ["new"]);
    });

    test("a requested refresh shows until newer data arrived", () async {
      final api = _FakeApi()..updatedAt = DateTime.utc(2026, 11, 18, 9);
      final container = await _container(
        api,
        browser: ({required url, required callbackUrlScheme}) async => null,
      );
      await container.read(bankConsentIdsProvider.notifier).add(_consentId);
      // keep the auto-dispose provider alive between reads
      container.listen(bankConnectionsProvider, (_, _) {});

      var connection = (await container.read(
        bankConnectionsProvider.future,
      )).single;
      expect(connection.refreshing, isFalse);

      await container.read(bankConnectorProvider).refresh(connection);
      expect(api.refreshed, [_consentId]);
      connection = (await container.read(
        bankConnectionsProvider.future,
      )).single;
      expect(connection.refreshing, isTrue);

      api.updatedAt = DateTime.utc(2026, 11, 18, 10);
      container.invalidate(bankConnectionsProvider);
      await container.read(bankConnectionsProvider.future);
      await Future<void>.delayed(Duration.zero);
      connection = (await container.read(
        bankConnectionsProvider.future,
      )).single;
      expect(connection.refreshing, isFalse);
      expect(connection.updatedAt, DateTime.utc(2026, 11, 18, 10));
    });
  });
}
