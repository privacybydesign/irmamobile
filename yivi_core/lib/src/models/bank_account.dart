/// Where a bank connection is in its life, as reported by the PSD2 issuer.
enum BankConnectionStatus {
  /// The bank data is still being fetched.
  pending,

  /// The accounts can be read.
  ready,

  /// The connection failed or is no longer valid at the bank.
  failed,

  /// The consent no longer exists: it expired or was removed.
  gone,
}

/// A bank that can be connected.
class Bank {
  /// The key the account information service knows the bank by.
  final String key;
  final String name;
  final String logoUrl;

  const Bank({required this.key, required this.name, this.logoUrl = ""});

  factory Bank.fromJson(Map<String, dynamic> json) => Bank(
    key: json["key"] as String,
    name: json["name"] as String? ?? json["key"] as String,
    logoUrl: json["logo_url"] as String? ?? "",
  );
}

class BankBalance {
  final double amount;
  final String currency;
  final DateTime? date;

  const BankBalance({required this.amount, required this.currency, this.date});

  factory BankBalance.fromJson(Map<String, dynamic> json) => BankBalance(
    amount: (json["amount"] as num).toDouble(),
    currency: json["currency"] as String? ?? "",
    date: _parseDate(json["date"]),
  );
}

class BankAccount {
  final String id;
  final String iban;
  final String bban;
  final String holder;
  final String currency;
  final BankBalance? balance;

  const BankAccount({
    required this.id,
    this.iban = "",
    this.bban = "",
    this.holder = "",
    this.currency = "",
    this.balance,
  });

  /// The account number to show: the IBAN when there is one.
  String get number => iban.isNotEmpty ? iban : bban;

  factory BankAccount.fromJson(Map<String, dynamic> json) => BankAccount(
    id: json["id"] as String,
    iban: json["iban"] as String? ?? "",
    bban: json["bban"] as String? ?? "",
    holder: json["holder"] as String? ?? "",
    currency: json["currency"] as String? ?? "",
    balance: json["balance"] is Map<String, dynamic>
        ? BankBalance.fromJson(json["balance"] as Map<String, dynamic>)
        : null,
  );
}

/// One consent at one bank, with the accounts the user gave access to.
class BankConnection {
  final String consentId;
  final BankConnectionStatus status;

  /// The bank, as the key the account information service knows it by.
  final String bank;

  /// The name and logo of the bank, when the service knows them.
  final String bankName;
  final String bankLogoUrl;

  /// Whether fresh data is being fetched from the bank right now.
  final bool refreshing;
  final DateTime? expiresAt;
  final DateTime? updatedAt;
  final List<BankAccount> accounts;

  const BankConnection({
    required this.consentId,
    required this.status,
    this.bank = "",
    this.bankName = "",
    this.bankLogoUrl = "",
    this.refreshing = false,
    this.expiresAt,
    this.updatedAt,
    this.accounts = const [],
  });

  const BankConnection.gone(this.consentId)
    : status = BankConnectionStatus.gone,
      bank = "",
      bankName = "",
      bankLogoUrl = "",
      refreshing = false,
      expiresAt = null,
      updatedAt = null,
      accounts = const [];

  /// What to call the bank: its name, or else the key it is known by.
  String get bankDisplayName => bankName.isNotEmpty ? bankName : bank;

  BankConnection copyWith({List<BankAccount>? accounts, bool? refreshing}) =>
      BankConnection(
        consentId: consentId,
        status: status,
        bank: bank,
        bankName: bankName,
        bankLogoUrl: bankLogoUrl,
        refreshing: refreshing ?? this.refreshing,
        expiresAt: expiresAt,
        updatedAt: updatedAt,
        accounts: accounts ?? this.accounts,
      );

  factory BankConnection.fromJson(
    String consentId,
    Map<String, dynamic> json,
  ) => BankConnection(
    consentId: consentId,
    status: switch (json["status"]) {
      "ready" => BankConnectionStatus.ready,
      "failed" => BankConnectionStatus.failed,
      _ => BankConnectionStatus.pending,
    },
    bank: json["bank"] as String? ?? "",
    bankName: json["bank_name"] as String? ?? "",
    bankLogoUrl: json["bank_logo_url"] as String? ?? "",
    refreshing: json["refreshing"] as bool? ?? false,
    expiresAt: _parseDate(json["expires_at"]),
    updatedAt: _parseDate(json["updated_at"]),
    accounts: [
      for (final account in json["accounts"] as List<dynamic>? ?? const [])
        BankAccount.fromJson(account as Map<String, dynamic>),
    ],
  );
}

class BankTransaction {
  final String id;
  final String accountId;
  final DateTime? date;
  final double amount;
  final String currency;
  final String description;
  final String counterpart;
  final String counterpartAccount;

  const BankTransaction({
    required this.id,
    required this.accountId,
    required this.amount,
    this.date,
    this.currency = "",
    this.description = "",
    this.counterpart = "",
    this.counterpartAccount = "",
  });

  /// What to call the transaction in a list: who it was with, or else what
  /// the bank says about it.
  String get title => counterpart.isNotEmpty
      ? counterpart
      : description.isNotEmpty
      ? description
      : counterpartAccount;

  factory BankTransaction.fromJson(Map<String, dynamic> json) =>
      BankTransaction(
        id: json["id"] as String? ?? "",
        accountId: json["account_id"] as String? ?? "",
        date: _parseDate(json["date"]),
        amount: (json["amount"] as num).toDouble(),
        currency: json["currency"] as String? ?? "",
        description: json["description"] as String? ?? "",
        counterpart: json["counterpart"] as String? ?? "",
        counterpartAccount: json["counterpart_account"] as String? ?? "",
      );
}

DateTime? _parseDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
