import "eudi_disclosure_sessions_empty_app_scenarios_test.dart"
    as empty_app_scenarios;
import "eudi_disclosure_sessions_filled_app_scenarios_test.dart"
    as filled_app_scenarios;
import "eudi_disclosure_sessions_special_scenarios_test.dart"
    as special_scenarios;

void main() {
  empty_app_scenarios.main();
  filled_app_scenarios.main();
  special_scenarios.main();
}
