import "dart:io";

import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/data/irma_mock_bridge.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";

void main() {
  group("IrmaRepository.allOperatingSystems", () {
    test(
      "allOperatingSystems matches Platform.operatingSystem documentation",
      () {
        // The constant should include all values documented at:
        // https://api.flutter.dev/flutter/dart-io/Platform/operatingSystem.html
        const expectedOses = [
          "android",
          "fuchsia",
          "ios",
          "linux",
          "macos",
          "windows",
        ];

        expect(
          IrmaRepository.allOperatingSystems.toSet(),
          equals(expectedOses.toSet()),
        );
      },
    );

    test("contains the current platform", () {
      // Whatever platform we're running on should be in the list
      expect(
        IrmaRepository.allOperatingSystems,
        contains(Platform.operatingSystem),
      );
    });
  });

  group("getExternalBrowserURLs", () {
    late IrmaRepository repo;
    late IrmaMockBridge mockBridge;

    setUp(() async {
      mockBridge = IrmaMockBridge();
      final preferences = await IrmaPreferences.fromInstance(
        mostRecentTermsUrlEn: "testurl",
        mostRecentTermsUrlNl: "testurl",
      );
      preferences.markLatestTermsAsAccepted(true);
      repo = IrmaRepository(client: mockBridge, preferences: preferences);

      // Wait for the repository to initialize by getting the IrmaConfiguration
      // This ensures all async initialization is complete before tests run
      await repo.getIrmaConfiguration().first;
    });

    tearDown(() async {
      await mockBridge.close();
      await repo.close();
    });

    test("returns a stream that emits lists of URLs", () async {
      final urls = await repo.getExternalBrowserURLs().first;

      expect(urls, isA<List<String>>());
    });

    test("excludes iOS-only credential URLs on non-iOS platforms", () async {
      // Skip this test if we're running on iOS
      if (Platform.isIOS) {
        return;
      }

      final urls = await repo.getExternalBrowserURLs().first;

      // pbdf.gemeente.address and pbdf.gemeente.personalData are iOS-only
      // Their IssueURL is "https://yivi.nijmegen.nl"
      // (from https://github.com/privacybydesign/pbdf-schememanager)
      // This URL should NOT be in the list on non-iOS platforms
      const gemeenteIssueUrl = "https://yivi.nijmegen.nl";
      expect(
        urls,
        isNot(contains(gemeenteIssueUrl)),
        reason:
            "iOS-only credential URLs should not be included on non-iOS platforms",
      );
    });

    test(
      "excludes Android-only credential URLs on non-Android platforms",
      () async {
        // Skip this test if we're running on Android
        if (Platform.isAndroid) {
          return;
        }

        final urls = await repo.getExternalBrowserURLs().first;

        // pbdf.pbdf.idin is Android-only
        // Its IssueURL is "https://idin-issuer.yivi.app/"
        // (from https://github.com/privacybydesign/pbdf-schememanager)
        const idinIssueUrl = "https://idin-issuer.yivi.app/";

        expect(
          urls,
          isNot(contains(idinIssueUrl)),
          reason:
              "Android-only credential URLs should not be included on non-Android platforms",
        );
      },
    );
  });
}
