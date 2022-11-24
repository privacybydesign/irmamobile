// We cannot test using null safety as long as there are widgets that are not migrated yet.
// @dart=2.11

import 'activity_test.dart' as activity_test;
import 'enroll_test.dart' as enroll_test;
import 'issuance_test.dart' as issuance_test;
import 'login_test.dart' as login_test;
import 'more_tab_test.dart' as more_tab_test;
import 'settings_test.dart' as settings_test;
import 'home_test.dart' as home_test;
import 'disclosure_session/disclosure_session_test.dart' as disclosure_session;

/// Wrapper to execute all tests at once.
void main() {
  enroll_test.main();
  login_test.main();
  settings_test.main();
  issuance_test.main();
  more_tab_test.main();
  activity_test.main();
  home_test.main();
  disclosure_session.main();
}
