import 'package:flutter_test/flutter_test.dart';
import 'package:irmamobile/src/models/session.dart';

void main() {
  test('Create session pointer from URI', () {
    const url =
        'https://privacybydesign.foundation/tomcat/irma_api_server/api/v2/verification/DhimFIgKWVhGjBgUOihzIHKQsMMTDHIbULI0xEpWXAx';
    const irmaQr = 'disclosing';
    final positiveTestCases = [
      'irma://qr/json/{"u":"$url","irmaqr":"$irmaQr"}',
      'https://irma.app/-pilot/session#{"u":"$url","irmaqr":"$irmaQr"}',
      'irma://qr/json/{"wizard":"test"}',
      'https://irma.app/-pilot/session#{"wizard":"test"}',
      'irma://qr/json/{"wizard":"test","u":"$url","irmaqr":"$irmaQr"}',
      'https://irma.app/-pilot/session#{"wizard":"test","u":"$url","irmaqr":"$irmaQr"}',
    ];

    for (final testCase in positiveTestCases) {
      final pointer = Pointer.fromString(testCase);
      if (testCase.contains('wizard')) {
        expect(pointer, isA<IssueWizardPointer>());
        final wizardPointer = pointer as IssueWizardPointer;
        expect(wizardPointer.wizard, 'test');
      } else {
        expect(pointer, isNot(isA<IssueWizardPointer>()));
      }

      if (testCase.contains('irmaqr')) {
        expect(pointer, isA<SessionPointer>());
        final sessionPointer = pointer as SessionPointer;
        expect(sessionPointer.u, url);
        expect(sessionPointer.irmaqr, irmaQr);
      } else {
        expect(pointer, isNot(isA<SessionPointer>()));
      }
    }

    expect(
      () => Pointer.fromString('https://privacybydesign.foundation/'),
      throwsA(const TypeMatcher<MissingPointer>()),
    );
  });
}
