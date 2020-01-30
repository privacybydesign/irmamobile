import 'package:flutter_test/flutter_test.dart';
import 'package:irmamobile/src/screens/webview/models/session_pointer.dart';

void main() {
  test('Create session pointer from URI', () {
    const url =
        'https://privacybydesign.foundation/tomcat/irma_api_server/api/v2/verification/DhimFIgKWVhGjBgUOihzIHKQsMMTDHIbULI0xEpWXAx';
    const irmaQr = 'disclosing';
    final positiveTestCases = [
      'intent://qr/json/{"u":"$url","v":"2.0","vmax":"2.4","irmaqr":"disclosing"}',
      'https://irma.app/testcase/session#{"u":"$url","v":"2.0","vmax":"2.4","irmaqr":"$irmaQr"}'
    ];

    for (final testCase in positiveTestCases) {
      final pointer = DeprecateMeSessionPointer.fromURI(testCase);
      expect(pointer.u, url);
      expect(pointer.irmaqr, irmaQr);
    }

    expect(
        () => DeprecateMeSessionPointer.fromURI("https://privacybydesign.foundation/"), throwsA(MissingSessionPointer));
  });
}
