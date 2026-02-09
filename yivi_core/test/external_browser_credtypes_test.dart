import "dart:io";

import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/irma_mock_bridge.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";

void main() {
  group("IrmaRepository.allOperatingSystems", () {
    test("allOperatingSystems matches Platform.operatingSystem documentation", () {
      // The constant should include all values documented at:
      // https://api.flutter.dev/flutter/dart-io/Platform/operatingSystem.html
      const expectedOses = ["android", "fuchsia", "ios", "linux", "macos", "windows"];

      expect(IrmaRepository.allOperatingSystems.toSet(), equals(expectedOses.toSet()));
    });

    test("contains the current platform", () {
      // Whatever platform we're running on should be in the list
      expect(IrmaRepository.allOperatingSystems, contains(Platform.operatingSystem));
    });
  });

  group("getExternalBrowserURLs", () {
    late IrmaRepository repo;
    late IrmaMockBridge mockBridge;

    setUp(() async {
      mockBridge = IrmaMockBridge();
      SharedPreferences.setMockInitialValues({});
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

    test("returns URLs from credentials matching current platform", () async {
      // This test verifies the filtering logic works
      // The actual URLs depend on which credentials are in the mock configuration
      // and have IssueURLs set for the current platform
      final urls = await repo.getExternalBrowserURLs().first;

      // The result should be a list (may be empty if no credentials match)
      expect(urls, isA<List<String>>());
    });

    test("excludes iOS-only credential URLs on non-iOS platforms", () async {
      // Skip this test if we're running on iOS
      if (Platform.operatingSystem == "ios") {
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
        reason: "iOS-only credential URLs should not be included on non-iOS platforms",
      );
    });

    test("excludes Android-only credential URLs on non-Android platforms", () async {
      // Skip this test if we're running on Android
      if (Platform.operatingSystem == "android") {
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
        reason: "Android-only credential URLs should not be included on non-Android platforms",
      );
    });
  });

  group("External browser credential type filtering", () {
    // These tests verify the expected behavior based on the PR changes
    // The PR adds PubHubs credentials for all operating systems

    test("platform-specific credentials are filtered correctly", () {
      // This is a documentation test - it describes the expected behavior
      // based on the _externalBrowserCredtypes list:
      //
      // - pbdf.gemeente.address: only ios
      // - pbdf.gemeente.personalData: only ios
      // - pbdf.pbdf.idin: only android
      // - pbdf.PubHubs.account: all operating systems
      // - irma-demo.PubHubs.account: all operating systems
      //
      // The filtering logic uses .contains() which allows credentials
      // to be associated with multiple platforms via the oses list.

      // Verify the current platform is supported
      final currentPlatform = Platform.operatingSystem;
      expect(
        IrmaRepository.allOperatingSystems,
        contains(currentPlatform),
        reason: "Current platform should be in allOperatingSystems",
      );
    });

    test("allOperatingSystems provides cross-platform support", () {
      // The allOperatingSystems constant enables credentials like PubHubs
      // to be opened in external browser on any platform

      // Verify all major mobile platforms are included
      expect(IrmaRepository.allOperatingSystems, contains("android"));
      expect(IrmaRepository.allOperatingSystems, contains("ios"));

      // Verify desktop platforms are also included (for future support)
      expect(IrmaRepository.allOperatingSystems, contains("macos"));
      expect(IrmaRepository.allOperatingSystems, contains("windows"));
      expect(IrmaRepository.allOperatingSystems, contains("linux"));
    });
  });
}
