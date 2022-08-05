// We cannot test using null safety as long as there are widgets that are not migrated yet.
// @dart=2.11

import 'aboutirma_test.dart' as aboutirma_test;
// import 'activity_test.dart' as activity_test;
// import 'enroll_test.dart' as enroll_test;
// import 'issuance_test.dart' as issuance_test;
// import 'login_test.dart' as login_test;
// import 'screens_test.dart' as screens_test;
// import 'settings_test.dart' as settings_test;

/// Wrapper to execute all tests at once.
void main() {
  // TODO: most tests are disabled because they do not work at the moment.
  // enroll_test.main();
  // screens_test.main();
  // login_test.main();
  // settings_test.main();
  // issuance_test.main();
  aboutirma_test.main();
  // activity_test.main();
  // home_test.main();
}
