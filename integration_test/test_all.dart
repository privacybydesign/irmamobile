import 'activity_test.dart' as activity_test;
import 'data_search_test.dart' as search_test;
import 'disclosure_session/disclosure_session_test_all.dart' as disclosure_session;
import 'enroll_test.dart' as enroll_test;
import 'issuance_test.dart' as issuance_test;
import 'issue_wizard_test.dart' as issue_wizard_test;
import 'login_test.dart' as login_test;
import 'more_tab_test.dart' as more_tab_test;
import 'new_terms_test.dart' as new_terms;
import 'notifications_test.dart' as notifications_test;
import 'qr_on_pin_screen_test.dart' as qr_on_pin_screen_test;
import 'reorder_cards_test.dart' as reorder_cards_test;
import 'settings_test.dart' as settings_test;

/// Wrapper to execute all tests at once.
void main() {
  reorder_cards_test.main();
  new_terms.main();
  search_test.main();
  qr_on_pin_screen_test.main();
  enroll_test.main();
  login_test.main();
  settings_test.main();
  issuance_test.main();
  more_tab_test.main();
  activity_test.main();
  disclosure_session.main();
  issue_wizard_test.main();
  notifications_test.main();
}
