import 'package:flutter_test/flutter_test.dart';
import 'package:irmamobile/src/screens/issuance_webview/models/session_pointer.dart';

void main() {
  test('Create session pointer from URI', () {
    var url =
        'https://privacybydesign.foundation/tomcat/irma_api_server/api/v2/verification/DhimFIgKWVhGjBgUOihzIHKQsMMTDHIbULI0xEpWXAx';
    var irmaQr = 'disclosing';
    var positiveTestCases = [
      'intent://qr/json/{"u":"$url","v":"2.0","vmax":"2.4","irmaqr":"disclosing"}',
      'https://irma.app/testcase/session#{"u":"$url","v":"2.0","vmax":"2.4","irmaqr":"$irmaQr"}'
    ];

    for (final testCase in positiveTestCases) {
      final pointer = SessionPointer.fromURI(testCase);
      expect(pointer.u, url);
      expect(pointer.irmaqr, irmaQr);
    }

    expect(() => SessionPointer.fromURI("https://privacybydesign.foundation/"), throwsA(MissingSessionPointer));
  });
}
