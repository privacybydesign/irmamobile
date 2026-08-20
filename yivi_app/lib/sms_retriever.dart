// Sms retriever on Android using the User Consent API.
// Can later be upgraded to use the SMS Retriever API to make the UX even better.
// See https://pub.dev/packages/pinput#sms-autofill for more info.
import "package:pinput/pinput.dart";
import "package:smart_auth/smart_auth.dart";

class SmartAuthSmsRetriever implements SmsRetriever {
  const SmartAuthSmsRetriever(this.smartAuth);

  final SmartAuth smartAuth;

  @override
  Future<void> dispose() {
    return smartAuth.removeUserConsentApiListener();
  }

  @override
  Future<String?> getSmsCode() async {
    // A code of 6 characters with only capital letters and and numbers
    const smsCodeMatcher = "([A-Z0-9]{6})";
    final res = await smartAuth.getSmsWithUserConsentApi(
      matcher: smsCodeMatcher,
    );
    return res.data?.code;
  }

  @override
  bool get listenForMultipleSms => false;
}
