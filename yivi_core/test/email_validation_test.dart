import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/email/widgets/enter_email_screen.dart";

void main() {
  test("valid email addresses", () {
    const validEmails = [
      "john.doe@example.com",
      "john.doe+tag@example.com",
      "john.doe.test@sub.domain.example.com",
      "john-doe@example.com",
      "john_doe@example.com",
      "john_doe@test-example.com",
      "john2doe@test-example.com",
      "5john2doe@test-example.com",
    ];

    for (final email in validEmails) {
      expect(isValidEmail(email), true);
    }
  });

  test("invalid email addresses", () {
    const invalidEmails = [
      "John Doe <john.doe@example.com>",
      '"john.doe"@example.com',
      "john.doe@[127.0.0.1]",
      "  john.doe@example.com",
      " john.doe+tag@example.com",
      "john.doe.test@sub.domain.example.com  ",
      "john-doe@example.com ",
      "   john_doe@example.com   ",
      "john doe@test-example.com",
    ];

    for (final email in invalidEmails) {
      expect(isValidEmail(email), false);
    }
  });
}
