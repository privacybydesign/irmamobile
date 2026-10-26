import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/providers/email_issuance_provider.dart";
import "package:yivi_core/src/providers/resend_wait.dart";
import "package:yivi_core/src/providers/sms_issuance_provider.dart";
import "package:yivi_core/src/widgets/resend_countdown.dart";

class _Sms implements SmsIssuerApi {
  final sent = <String>[];
  var fail = false;

  @override
  Future<void> sendSms({
    required String phoneNumber,
    required String language,
  }) async {
    if (fail) throw SmsIssuanceRateLimitError();
    sent.add(phoneNumber);
  }

  @override
  Future<SessionPointer> verifyCode({
    required String phoneNumber,
    required String verificationCode,
  }) => throw UnimplementedError();
}

class _Email implements EmailIssuerApi {
  final sent = <String>[];

  @override
  Future<void> sendEmail({
    required String emailAddress,
    required String language,
  }) async => sent.add(emailAddress);

  @override
  Future<SessionPointer> verifyCode({
    required String email,
    required String verificationCode,
  }) => throw UnimplementedError();
}

void main() {
  late DateTime now;
  late _Sms sms;
  late _Email email;
  late ProviderContainer container;

  setUp(() {
    now = DateTime(2026, 10, 26, 9);
    sms = _Sms();
    email = _Email();
    container = ProviderContainer(
      overrides: [
        resendClockProvider.overrideWithValue(() => now),
        smsIssuerApiProvider.overrideWithValue(sms),
        emailIssuerApiProvider.overrideWithValue(email),
      ],
    );
    // Kept alive, as the flow's screens keep them.
    container.listen(smsIssuanceProvider, (_, _) {});
    container.listen(emailIssuanceProvider, (_, _) {});
  });
  tearDown(() => container.dispose());

  SmsIssuer smsIssuer() => container.read(smsIssuanceProvider.notifier);
  Future<void> sendSms(String n) =>
      smsIssuer().sendSms(phoneNumber: n, language: "en");

  group("SMS", () {
    test("the same number within a minute is ignored", () async {
      await sendSms("0612345678");
      now = now.add(const Duration(seconds: 59));
      await sendSms("0612345678");
      expect(sms.sent, ["0612345678"]);
      expect(smsIssuer().resendAt("0612345678"), DateTime(2026, 10, 26, 9, 1));
    });

    test("after the minute it goes again", () async {
      await sendSms("0612345678");
      now = now.add(const Duration(seconds: 60));
      expect(smsIssuer().resendAt("0612345678"), isNull);
      await sendSms("0612345678");
      expect(sms.sent, ["0612345678", "0612345678"]);
    });

    test("an ignored send does not start the minute again", () async {
      await sendSms("0612345678");
      now = now.add(const Duration(seconds: 30));
      await sendSms("0612345678");
      now = now.add(const Duration(seconds: 30));
      await sendSms("0612345678");
      expect(sms.sent, ["0612345678", "0612345678"]);
    });

    test("another number at once; the wait is per number", () async {
      await sendSms("0612345678");
      await sendSms("0687654321");
      // Back to the first: still waiting.
      await sendSms("0612345678");
      expect(sms.sent, ["0612345678", "0687654321"]);
    });

    test("a send that failed does not count", () async {
      sms.fail = true;
      await sendSms("0612345678");
      expect(smsIssuer().resendAt("0612345678"), isNull);
      sms.fail = false;
      await sendSms("0612345678");
      expect(sms.sent, ["0612345678"]);
    });
  });

  test("e-mail: the same minute per address", () async {
    final issuer = container.read(emailIssuanceProvider.notifier);
    await issuer.sendEmail(email: "jan@example.com", language: "en");
    await issuer.sendEmail(email: "jan@example.com", language: "en");
    await issuer.sendEmail(email: "piet@example.com", language: "en");
    expect(email.sent, ["jan@example.com", "piet@example.com"]);
    now = now.add(const Duration(minutes: 1));
    await issuer.sendEmail(email: "jan@example.com", language: "en");
    expect(email.sent, [
      "jan@example.com",
      "piet@example.com",
      "jan@example.com",
    ]);
  });

  test("the time left reads as minutes and seconds, rounded up", () {
    String f(int ms) => ResendCountdown.format(Duration(milliseconds: ms));
    expect(f(60000), "1:00");
    expect(f(59001), "1:00");
    expect(f(42000), "0:42");
    expect(f(100), "0:01");
  });
}
