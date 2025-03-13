import 'activity_test.dart' as activity_test;
import 'credential_store_test.dart' as credential_store_test;
import 'disclosure_session/disclosure_session_test_all.dart' as disclosure_session;
import 'enroll_test.dart' as enroll_test;
import 'home_test.dart' as home_test;
import 'issuance_test.dart' as issuance_test;
import 'issue_wizard_test.dart' as issue_wizard_test;
import 'login_test.dart' as login_test;
import 'more_tab_test.dart' as more_tab_test;
import 'notifications_test.dart' as notifications_test;
import 'qr_on_pin_screen_test.dart' as qr_on_pin_screen_test;
import 'settings_test.dart' as settings_test;

/// Wrapper to execute all tests at once.
void main() {
  qr_on_pin_screen_test.main();
  enroll_test.main();
  login_test.main();
  settings_test.main();
  issuance_test.main();
  more_tab_test.main();
  activity_test.main();
  home_test.main();
  disclosure_session.main();
  issue_wizard_test.main();
  credential_store_test.main();
  notifications_test.main();
}
