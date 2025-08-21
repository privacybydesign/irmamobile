import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import '../irma_binding.dart';
import 'helpers.dart';

Future<void> issueIrmaTubeMember(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) =>
    issueCredentials(tester, irmaBinding, {
      'irma-demo.IRMATube.member.type': 'USER',
      'irma-demo.IRMATube.member.id': '123123',
    });

Future<void> issueEmailAddress(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding, {
  Locale? locale,
  int? sdJwtBatchSize,
}) =>
    issueCredentials(
      tester,
      irmaBinding,
      locale: locale,
      {
        'irma-demo.sidn-pbdf.email.email': 'test@example.com',
        'irma-demo.sidn-pbdf.email.domain': 'example.com',
      },
      sdJwtBatchSize: sdJwtBatchSize,
    );

Future<void> issueMobileNumber(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) =>
    issueCredentials(tester, irmaBinding, {
      'irma-demo.sidn-pbdf.mobilenumber.mobilenumber': '0612345678',
    });

Future<void> issueMunicipalityAddress(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) =>
    issueCredentials(tester, irmaBinding, {
      'irma-demo.gemeente.address.street': 'Meander',
      'irma-demo.gemeente.address.houseNumber': '501',
      'irma-demo.gemeente.address.zipcode': '1234AB',
      'irma-demo.gemeente.address.city': 'Arnhem',
      'irma-demo.gemeente.address.municipality': 'Arnhem'
    });

Future<void> issueIdin(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) =>
    issueCredentials(tester, irmaBinding, {
      'irma-demo.idin.idin.initials': 'W.L.',
      'irma-demo.idin.idin.familyname': 'Bruijn',
      'irma-demo.idin.idin.dateofbirth': '10-04-1965',
      'irma-demo.idin.idin.gender': 'V',
      'irma-demo.idin.idin.address': 'Meander 501',
      'irma-demo.idin.idin.zipcode': '1234 AB',
      'irma-demo.idin.idin.city': 'Arnhem',
      'irma-demo.idin.idin.country': 'Netherlands',
    });

Future<void> issueDemoIvidoLogin(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding, {
  bool continueOnSecondDevice = true,
}) =>
    issueCredentials(
      tester,
      irmaBinding,
      {
        'irma-demo.ivido.login.identifier': 'ea0cdf95-a412-41f1-9e8d-56c2af310af9',
      },
      continueOnSecondDevice: continueOnSecondDevice,
    );

Map<String, String> createMunicipalityPersonalDataAttributes(Locale locale) {
  const credentialId = 'irma-demo.gemeente.personalData';

  if (locale.languageCode == 'nl') {
    return {
      '$credentialId.fullname': 'W.L. de Bruijn',
      '$credentialId.initials': 'W.L.',
      '$credentialId.firstnames': 'Willeke Liselotte',
      '$credentialId.prefix': 'de',
      '$credentialId.surname': 'de Bruijn',
      '$credentialId.familyname': 'Bruijn',
      '$credentialId.gender': 'V',
      '$credentialId.dateofbirth': '10-04-1965',
      '$credentialId.over12': 'Ja',
      '$credentialId.over16': 'Ja',
      '$credentialId.over18': 'Ja',
      '$credentialId.over21': 'Ja',
      '$credentialId.over65': 'Nee',
      '$credentialId.nationality': 'Ja',
      '$credentialId.cityofbirth': 'Arnhem',
      '$credentialId.countryofbirth': 'Arnhem',
      '$credentialId.bsn': '999999990',
      '$credentialId.digidlevel': 'Substantieel',
    };
  }

  if (locale.languageCode == 'en') {
    return {
      '$credentialId.fullname': 'W.L. de Bruijn',
      '$credentialId.initials': 'W.L.',
      '$credentialId.firstnames': 'Willeke Liselotte',
      '$credentialId.prefix': 'de',
      '$credentialId.surname': 'de Bruijn',
      '$credentialId.familyname': 'Bruijn',
      '$credentialId.gender': 'V',
      '$credentialId.dateofbirth': '10-04-1965',
      '$credentialId.over12': 'Yes',
      '$credentialId.over16': 'Yes',
      '$credentialId.over18': 'Yes',
      '$credentialId.over21': 'Yes',
      '$credentialId.over65': 'No',
      '$credentialId.nationality': 'Yes',
      '$credentialId.cityofbirth': 'Arnhem',
      '$credentialId.countryofbirth': 'Arnhem',
      '$credentialId.bsn': '999999990',
      '$credentialId.digidlevel': 'Substantieel',
    };
  }

  throw 'unsupported locale $locale';
}

Future<void> issueMunicipalityPersonalData(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding, {
  Locale locale = const Locale('en', 'EN'),
  bool continueOnSecondDevice = true,
  int? sdJwtBatchSize,
}) async {
  final attributes = createMunicipalityPersonalDataAttributes(locale);
  await issueCredentials(
    tester,
    irmaBinding,
    attributes,
    locale: locale,
    continueOnSecondDevice: continueOnSecondDevice,
    sdJwtBatchSize: sdJwtBatchSize,
  );
}

Future<void> issueDemoCredentials(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await issueEmailAddress(tester, irmaBinding);
  await issueMunicipalityPersonalData(tester, irmaBinding);
  await issueMunicipalityAddress(tester, irmaBinding);
}
