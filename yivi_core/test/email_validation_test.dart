import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/email/widgets/enter_email_screen.dart";

void main() {
  test("valid email addresses", () {
    expect(isValidEmail("john.doe@example.com"), true);
    expect(isValidEmail("john.doe+tag@example.com"), true);
    expect(isValidEmail("john.doe.test@sub.domain.example.com"), true);
    expect(isValidEmail("john-doe@example.com"), true);
    expect(isValidEmail("john_doe@example.com"), true);
    expect(isValidEmail("john_doe@test-example.com"), true);
  });

  test("invalid email addresses", () {
    expect(isValidEmail("John Doe <john.doe@example.com>"), false);
    expect(isValidEmail('"john.doe"@example.com'), false);
    expect(isValidEmail("john.doe@[127.0.0.1]"), false);

    expect(isValidEmail("  john.doe@example.com"), false);
    expect(isValidEmail(" john.doe+tag@example.com"), false);
    expect(isValidEmail("john.doe.test@sub.domain.example.com  "), false);
    expect(isValidEmail("john-doe@example.com "), false);
    expect(isValidEmail("   john_doe@example.com   "), false);
    expect(isValidEmail("john doe@test-example.com"), false);
  });
}
