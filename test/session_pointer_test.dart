import 'package:flutter_test/flutter_test.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:matcher/matcher.dart';

void main() {
  test('Create session pointer from URI', () {
    const url =
        'https://privacybydesign.foundation/tomcat/irma_api_server/api/v2/verification/DhimFIgKWVhGjBgUOihzIHKQsMMTDHIbULI0xEpWXAx';
    const irmaQr = 'disclosing';
    final positiveTestCases = [
      'irma://qr/json/{"u":"$url","v":"2.0","vmax":"2.4","irmaqr":"disclosing"}',
      'https://irma.app/-pilot/session#{"u":"$url","v":"2.0","vmax":"2.4","irmaqr":"$irmaQr"}'
    ];

    for (final testCase in positiveTestCases) {
      final pointer = SessionPointer.fromURI(testCase);
      expect(pointer.u, url);
      expect(pointer.irmaqr, irmaQr);
    }

    expect(() => SessionPointer.fromURI("https://privacybydesign.foundation/"),
        throwsA(const TypeMatcher<MissingSessionPointer>()));
  });
}
