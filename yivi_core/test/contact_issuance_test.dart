import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/providers/contact_issuance_provider.dart";
import "package:yivi_core/src/providers/resend_wait.dart";

final _pointer = SessionPointer(
  protocol: .irma,
  u: "https://example.com/session",
  irmaqr: "issuing",
);

/// What the issuer answers.
class _Issuer {
  final sent = <(String, String)>[];
  final verified = <(String, String)>[];

  /// Thrown by send or verify; [failWith] null: they succeed.
  Object? failWith;

  Future<void> send(String target, String language) async {
    if (failWith case final e?) throw e;
    sent.add((target, language));
  }

  Future<SessionPointer> verify(String target, String code) async {
    verified.add((target, code));
    if (failWith case final e?) throw e;
    return _pointer;
  }
}

class _Api implements ContactIssuerApi {
  _Api(this.issuer);
  final _Issuer issuer;

  @override
  Future<void> send({required String target, required String language}) =>
      issuer.send(target, language);

  @override
  Future<SessionPointer> verify({
    required String target,
    required String code,
  }) => issuer.verify(target, code);
}

/// The stage, in one word for both flows.
enum _Stage { address, sending, code }

/// What went wrong, in one word for both flows.
enum _Error { none, wrongCode, rateLimited, other }

/// One flow, e-mail or SMS, through the notifier the app uses.
class _Flow {
  _Flow(this.container, this.flow) {
    container.listen(contactIssuanceProvider(flow), (_, _) {});
  }
  final ProviderContainer container;
  final ContactFlow flow;

  ContactIssuance get _n =>
      container.read(contactIssuanceProvider(flow).notifier);
  ContactIssuanceState get _s => container.read(contactIssuanceProvider(flow));

  Object get wrongCode => const ContactWrongCode();
  Object get rateLimited => const ContactRateLimited();
  _Stage get stage => switch (_s.stage) {
    ContactStage.address => _Stage.address,
    ContactStage.sending => _Stage.sending,
    ContactStage.code => _Stage.code,
  };
  String get target => _s.target;
  _Error get error => switch (_s.error) {
    null => _Error.none,
    ContactWrongCode() => _Error.wrongCode,
    ContactRateLimited() => _Error.rateLimited,
    _ => _Error.other,
  };
  Future<void> send(String target) => _n.send(target, language: "nl");
  Future<SessionPointer?> verify(String code) => _n.verify(code);
  void back() => _n.backToAddress();
  DateTime? resendAt(String target) => _n.resendAt(target);

  void codeOnItsWay(String target) => _n.codeOnItsWay(target);
  bool get fromLink => _s.source == ContactSource.link;
}

/// Adding an e-mail address or a phone number: sending the code, the wait
/// before sending again, checking the code and its errors. One body for
/// both flows.
void main() {
  late DateTime now;
  late _Issuer issuer;
  late ProviderContainer container;

  setUp(() {
    now = DateTime(2026, 11, 17, 9);
    issuer = _Issuer();
    container = ProviderContainer(
      overrides: [
        resendClockProvider.overrideWithValue(() => now),
        emailIssuerApiProvider.overrideWithValue(_Api(issuer)),
        smsIssuerApiProvider.overrideWithValue(_Api(issuer)),
      ],
    );
  });
  tearDown(() => container.dispose());

  for (final (name, make, a, b) in [
    (
      "e-mail",
      (ProviderContainer c) => _Flow(c, ContactFlow.email),
      "ann@example.com",
      "bob@example.com",
    ),
    (
      "phone",
      (ProviderContainer c) => _Flow(c, ContactFlow.phone),
      "+31612345678",
      "+31687654321",
    ),
  ]) {
    group(name, () {
      test("send: sending, then the code for the target; the issuer got "
          "the target and the language", () async {
        final flow = make(container);
        expect(flow.stage, _Stage.address);
        final sending = flow.send(a);
        expect(flow.stage, _Stage.sending);
        expect(flow.target, a);
        await sending;
        expect(flow.stage, _Stage.code);
        expect(flow.error, _Error.none);
        expect(issuer.sent, [(a, "nl")]);
      });

      test("the issuer says no: back at the address with its error; the "
          "minute is not started", () async {
        final flow = make(container);
        issuer.failWith = flow.rateLimited;
        await flow.send(a);
        expect(flow.stage, _Stage.address);
        expect(flow.error, _Error.rateLimited);
        expect(flow.resendAt(a), isNull);
      });

      test("no connection: back at the address, the general error", () async {
        final flow = make(container);
        issuer.failWith = Exception("offline");
        await flow.send(a);
        expect(flow.stage, _Stage.address);
        expect(flow.error, _Error.other);
        expect(flow.resendAt(a), isNull);
      });

      test("the same target within the minute sends nothing; another at "
          "once", () async {
        final flow = make(container);
        await flow.send(a);
        now = now.add(const Duration(seconds: 30));
        await flow.send(a);
        expect(issuer.sent.map((s) => s.$1), [a]);
        expect(flow.resendAt(a), DateTime(2026, 11, 17, 9, 1));
        await flow.send(b);
        expect(issuer.sent.map((s) => s.$1), [a, b]);
      });

      test("verify right: the pointer for the target", () async {
        final flow = make(container);
        await flow.send(a);
        expect(await flow.verify("ABC123"), same(_pointer));
        expect(issuer.verified, [(a, "ABC123")]);
      });

      test("verify wrong: still the code, the wrong-code error", () async {
        final flow = make(container);
        await flow.send(a);
        issuer.failWith = flow.wrongCode;
        expect(await flow.verify("ABC123"), isNull);
        expect(flow.stage, _Stage.code);
        expect(flow.error, _Error.wrongCode);
      });

      test(
        "verify fails otherwise: still the code, the general error",
        () async {
          final flow = make(container);
          await flow.send(a);
          issuer.failWith = Exception("offline");
          expect(await flow.verify("ABC123"), isNull);
          expect(flow.stage, _Stage.code);
          expect(flow.error, _Error.other);
        },
      );

      test(
        "back to the address keeps the target and clears the error",
        () async {
          final flow = make(container);
          await flow.send(a);
          issuer.failWith = flow.wrongCode;
          await flow.verify("ABC123");
          flow.back();
          expect(flow.stage, _Stage.address);
          expect(flow.target, a);
          expect(flow.error, _Error.none);
        },
      );
    });
  }

  test("e-mail: a code on its way through the link skips sending", () {
    final flow = _Flow(container, ContactFlow.linkEmail);
    flow.codeOnItsWay("ann@example.com");
    expect(flow.stage, _Stage.code);
    expect(flow.target, "ann@example.com");
    expect(flow.fromLink, isTrue);
    expect(issuer.sent, isEmpty);
  });
}
