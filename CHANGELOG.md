# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased
### Added
- Credential status notifications
- Added scheme management functionality to the debug screen

### Changed
- Java distribution switch from Adopt to Temurin ([as recommended](https://github.com/actions/setup-java#supported-distributions))
- Update irmago to version 0.13.3
- Changed the message regarding error and app status reporting

### Fixed
- Voice over and accessibility tags are not correctly set on the PIN screen
- Required update screen refers to iTunes Store instead of Apple App Store
- iOS builds fail when using Golang 1.20 ([#117](https://github.com/privacybydesign/irmamobile/issues/117))

### Internal
- Add integration test for declining the credential offer in an issuance session
- Add integration test where two credentials of the same type are present and the user can choose between them
- Add integration test for reset from forgotten PIN scenario
- Add integration test for changing to a longer PIN
- Add integration test for calling session
- Add integration test for declining disclosure
- Add integration test for deletion of a credential
- Add integration test for the reissuing of a credential
- Finished random blind integration test

## [7.4.2] - 2023-06-22
### Fixed
- LoadingScreen StreamBuilder triggers multiple navigation actions
## [7.4.1] - 2023-06-15
### Added
- Show custom error message when the server returns a response indicating that the user is not registered

### Changed
- Replace breaking hyphens in requestor URLs with non-breaking hyphens

### Fixed
- Cold starting the app with a universal link fails to start a session

### Internal
- Refactored the IrmaMobileBridgePlugin from Objective-C to Swift

## [7.4.0] - 2023-05-25
### Added
- Show notification on startup that the app name has changed

### Changed
- Upgrade to Flutter 3
- Bump irmago version to [0.12.5](https://github.com/privacybydesign/irmago/releases/tag/v0.12.5)
- Pin the personal category to the top of credential store
- Report warnings from irmago to Sentry

### Fixed
- QR scanner library is not FOSS ([#163](https://github.com/privacybydesign/irmamobile/issues/163))
- Dutch translations link to English version of the privacy policy
- Some newlines are preceded by whitespace
- App screenshots are not placed in the right directory for FDroid
- Arrow back screen shows a message about signing when doing issuance

### Internal
- Use 'flutter build ipa' in Fastlane to build iOS app
- Bump fastlane version to 2.212.2

## [7.3.1] - 2023-05-04 (in beta 2023-04-26)
### Changed
- Randomize which success graphic is shown
- Set color of browser toolbar in custom tabs on Android to white
- Clarify texts to better distinguish signing sessions from regular disclosure sessions

### Fixed
- Scheme update mechanism is not called at every app start-up
- Anonymous app health information is being collected when error reporting is disabled
- Text could overflow its UI container on the PIN screen
- Options menu to delete data is not visible when data is expired or revoked
- Unsafe irma.SessionError type cast causes panics
- Exclude superfluous x86 library assets from Android app bundle

### Internal
- Bump native_device_orientation Flutter dependency to 1.1.4
- Bump activesupport Ruby dependency to 6.1.7.3
- Improved stability of entering PIN codes in integration tests

## [7.3.0] - 2023-04-11 (in beta 2023-04-05)
### Added
- Setting to select app language

### Changed
- Use Yivi Twitter profile and meetups link

### Fixed
- Only a limited number of activities shown in the activity overview

## [7.2.0] - 2023-04-04 (in beta 2023-03-28)
### Added
- Show notification when camera permissions are denied

### Changed
- User interface of QR scanner screen
- Scale all logos as avatars
- Use the 'add' icon as trailing icon on add data cards
- Build target set to Android 13 (API level 33)

### Fixed
- Increase touchable area and improve responsiveness of PIN inputs
- PIN session token becomes invalid after the PIN is changed
- Prevent black screens to be shown when finishing a session with a clientReturnUrl

## [7.1.0] - in beta 2023-03-22
### Added
- Extra animation during onboarding
- Opt-in for error reporting during onboarding
- Information dialog for invalid credentials that are not obtainable in an online flow

### Changed
- Settings screen: active toggle color changed
- Prefer non-revoked or expired credentials during attribute request flows
- Change choice option no longer visible when only one choice is possible
- New layout for data screen
- Increased safe space on onboarding screens
- Changed remaining IRMA style buttons to Yivi themed versions

### Fixed
- Incorrect return behavior when cancelling session request ([#134](https://github.com/privacybydesign/irmamobile/issues/134))
- Arrow back screen not properly aligned in landscape mode
- PIN incorrect dialog button text not scaling properly
- Voice over - accessibility tags properly set so semantics are working again
- Missing shadow at some UI elements
- Signed message disappears when changing choices in a signature session

## [7.0.1] - in beta 2023-03-09
### Changed
- Illustration on pin forgotten screen is updated
- Category names are no longer shown twice on credential detail screens

### Fixed
- Starting a custom issue wizard fails
- ArrowBackScreen (iOS) is not always closed properly
- Button to re-obtain expired or revoked credentials is missing within a session
- Old log entries may not have a hostnames field ([#103](https://github.com/privacybydesign/irmamobile/issues/103))
- Pretty verifier logos are not shown properly ([#104](https://github.com/privacybydesign/irmamobile/issues/104))
- HistoryRepository: Cannot add to unmodifiable list ([#105](https://github.com/privacybydesign/irmamobile/issues/105))
- SessionScreen: Null check operator used on null value ([#111](https://github.com/privacybydesign/irmamobile/issues/111))

## [7.0.0] - in beta 2023-02-20
### Added
- First public release styled with new Yivi brand
- New user interface and usability improvements
- Improved attribute request flow
- Secure PIN logic (warns when users select an insecure PIN)

Please note: Some graphics are linked to the IRMA scheme and will show placeholder icons until this version is released to production. The release date is 2023-04-04.

## [6.4.1] - 2023-02-16 (in beta 2023-02-14)
### Fixed
- Leftover 'oldscheme...' and 'tempscheme...' directories cause issues when parsing IrmaConfiguration ([privacybydesign/irmago#284](https://github.com/privacybydesign/irmago/issues/284))

## [6.4.0] - 2023-02-09 (in beta 2023-01-23)
### Added
- Use the device's Trusted Execution Environment / Secure Enclave as additional security factor for the PIN authentication
- 'IRMA becomes Yivi' announcement

### Fixed
- Bug in error message parsing causes panics ([#28](https://github.com/privacybydesign/irmamobile/issues/28))
- Issuer schemes can get out-of-sync after interrupted scheme update ([#66](https://github.com/privacybydesign/irmamobile/issues/66))
- Avoid gocron panics in revocation code during irmaclient startup ([privacybydesign/irmago#249](https://github.com/privacybydesign/irmago/pull/249))

## [6.3.3] - 2023-01-23 (in beta 2022-12-16)
### Added
- Possibility to run integration tests on Android with JUnit using a test environment of the keyshare server

### Changed
- Updated irmago dependency
- Moved active development and CI/CD workflows to GitHub

### Fixed
- Typo in English texts on 'About IRMA' screen

## [6.3.2] - 2022-09-23 (in beta 2022-09-20)
This release only includes iOS changes.

### Changed
- Enforce that minimum iOS version has been increased to 12

### Fixed
- App crashes on iOS12 devices due to missing secure enclave functionality

## [6.3.1] - 2022-09-20 (in beta 2022-08-29)
### Changed
- Remove 'account' from explanations

## [6.3.0] - 2022-08-29 (in beta 2022-07-06)
### Added
- The internal storage of attributes and previous session data is now encrypted

### Changed
- Minimum iOS version increased to iOS 12

### Fixed
- Fixed the app not locking after 5 minutes on some devices

## [6.2.4] - in beta 2022-04-12
### Added
- New preference in Settings screen on Android to enable screenshots

### Changed
- When the full session request is not entirely visible, the disabled "Yes" button has changed to a "More" button that scrolls down

### Fixed
- Switched to external browser for iDIN issuance on Android to avoid issues with toggling to bank app

### Security
- Disallow TLS cipher suites that are no longer considered secure

## [6.2.3] - 2022-01-10 (in beta 2022-01-06)
### Fixed
- Fixed crash on Android 6 when scanning QR codes
- Fixed session screen not updating when issuing a non-singleton during disclosure
- Fixed race condition on Android causing it sometimes to not pick up the universal link during startup

## [6.2.2] - 2021-12-24 (in beta 2021-11-30)
### Added
- Integration tests (partly) for the following screens: about, enrollment, history, issuance, PIN entry, settings, wallet

### Changed
- Improved session screen when specific attribute values are requested that are not present
- Improved return URL and return phone number handling
- Partially migrated to null-safe Dart

### Fixed
- HTTPS connections with servers using Let's Encrypt TLS certificates should now again work on Android 7-
- Fixed bug where universal link was sometimes dropped on iOS when app was not already running
- Fixed glitch in history screen due to null deref when showing issuance of revokable credential
- Universal links to other apps should work again
- Order of cards in the wallet is now always stable

## [6.2.1] - 2021-11-30 (in beta 2021-08-27)
### Changed
- Migrated to Flutter 2
- Small improvements to English texts
- Made some error cases non-reportable

### Fixed
- Crash on session requests containing non-attribute disclosures (e.g. "irma-demo.MijnOverheid.fullName" instead of "irma-demo.MijnOverheid.fullName.familyname")

## [6.2.0] - 2021-08-27 (in beta 2021-08-02)
### Added
- Support for device pairing to protect against shoulder surfing (QR code stealing)

### Fixed
- Several small bug fixes

## [6.1.2] - 2021-08-02 (in beta 2021-07-15)
### Fixed
- Keyboard not reappearing during enrollment when toggling away and back from/to app
- Make email notice after enrollment scrollable on small screens
- On expired cards that cannot be refreshed, change refresh button into remove button

## [6.1.1] - 2021-07-08 (in beta 2021-06-09)
### Changed
- Decreased header size of card info screen (from "Adding cards") and wizard screen
- Decreased logging to system log

### Fixed
- Bug leading to some logs not being shown in error screen

## [6.1.0] - in beta 2021-03-26
### Added
- Support for human-readable verifier names, optionally including logo
- Support for issuance wizards for obtaining a sequence of cards

### Fixed
- Fixed in-app SMS issuance website disappearing when toggling away from and back to the app
- Various other bug fixes and improvements

## [6.0.12] - 2021-03-17 (in beta 2021-02-03)
### Changed
- Various accessibility improvements
- Made text of refuse button in session screen more neutral

### Fixed
- Small bugfix in QR code scanner
- Keyboard on PIN screen vanishing in some cases

## [6.0.11] - 2021-01-20 (in beta 2021-01-15)
### Changed
- Improved usability of app for screen reader users
- Session done screen now closes automatically when closing app

### Fixed
- Several small bugs that would occasionally cause the app to hang

## [6.0.10] - 2020-11-13 (in beta 2020-10-30)
### Added
- Implemented translation of yes/no attribute values
- During disclosure, allow issuance of additional card instances (for cards that support so, e.g. email) to allow users to disclose attribute values they do not yet have

### Changed
- Improved clarity of error screen for common cases
- Use in-app browser for AGB card
- Indicated headers as such for screen reader for visually impaired
- Improve grays and colors for more contrast in QR scanner

### Fixed
- Several rare issues that caused crashes
- Tooltips during enrollment
- Solved bug that could freeze the GUI in case of slow IRMA server
- Use external browser for links to MyIRMA and demo's in Help and About IRMA screens
- Bug that would cause disclosure options to swap order during a specific case in disclosure sessions
- Bug making it impossible to issue AGB card during disclosure if the user did not already have an AGB card


## [6.0.9] - 2020-10-07 (in beta 2020-09-15)
### Added
- Automatically starting the QR scanner when enabled from settings screen

### Changed
- Switched browser type used when starting issuance from app

## [6.0.8] - 2020-09-11 (in beta 2020-09-03)
### Fixed
- Various small bug fixes


## [6.0.5] - in beta 2020-08-07
### Fixed
- Small race conditions during session start


## [6.0.4] - 2020-08-20 (in beta 2020-07-22)
### Fixed
- App crashing immediately after starting it
- Clarified message when requested information doesn't match what the user has
- Fixed crash on requesting only information the user does not have and can no longer obtain

## [6.0.3] - 2020-07-21 (in beta 2020-07-07)
### Fixed
- Layout issue of wallet on phones with large notches


## [6.0.2] - 2020-06-30 (in beta 2020-06-17)
### Fixed
- Issue that caused keyboard to disappear on some android devices
- Incorrect back icon on history screen


## [6.0.1] - 2020-06-03 (in beta 2020-06-03)
### Fixed
- Missing text in combined issuance-disclosure sessions


## [6.0.0] - 2020-06-03 (in beta 2020-05-30)
### Changed
- Completely new look for the app

### Added
- When missing or expired attributes are requested, they can now be retrieved and disclosed during the session
- Authentication by phone with IRMA calling

### Fixed
- Log screen now shows all log items
- Various bug fixes

[7.4.2]: https://github.com/privacybydesign/irmamobile/compare/v7.4.1...v7.4.2
[7.4.1]: https://github.com/privacybydesign/irmamobile/compare/v7.4.0...v7.4.1
[7.4.0]: https://github.com/privacybydesign/irmamobile/compare/v7.3.1...v7.4.0
[7.3.1]: https://github.com/privacybydesign/irmamobile/compare/v7.3.0...v7.3.1
[7.3.0]: https://github.com/privacybydesign/irmamobile/compare/v7.2.0...v7.3.0
[7.2.0]: https://github.com/privacybydesign/irmamobile/compare/v7.1.0...v7.2.0
[7.1.0]: https://github.com/privacybydesign/irmamobile/compare/v7.0.1...v7.1.0
[7.0.1]: https://github.com/privacybydesign/irmamobile/compare/v7.0.0...v7.0.1
[7.0.0]: https://github.com/privacybydesign/irmamobile/compare/v6.4.1...v7.0.0
[6.4.1]: https://github.com/privacybydesign/irmamobile/compare/v6.4.0...v6.4.1
[6.4.0]: https://github.com/privacybydesign/irmamobile/compare/v6.3.3...v6.4.0
[6.3.3]: https://github.com/privacybydesign/irmamobile/compare/v6.3.2...v6.3.3
[6.3.2]: https://github.com/privacybydesign/irmamobile/compare/v6.3.1...v6.3.2
[6.3.1]: https://github.com/privacybydesign/irmamobile/compare/v6.3.0...v6.3.1
[6.3.0]: https://github.com/privacybydesign/irmamobile/compare/v6.2.4...v6.3.0
[6.2.4]: https://github.com/privacybydesign/irmamobile/compare/v6.2.3...v6.2.4
[6.2.3]: https://github.com/privacybydesign/irmamobile/compare/v6.2.2...v6.2.3
[6.2.2]: https://github.com/privacybydesign/irmamobile/compare/v6.2.1...v6.2.2
[6.2.1]: https://github.com/privacybydesign/irmamobile/compare/v6.2.0...v6.2.1
[6.2.0]: https://github.com/privacybydesign/irmamobile/compare/v6.1.2...v6.2.0
[6.1.2]: https://github.com/privacybydesign/irmamobile/compare/v6.1.1...v6.1.2
[6.1.1]: https://github.com/privacybydesign/irmamobile/compare/v6.1.0...v6.1.1
[6.1.0]: https://github.com/privacybydesign/irmamobile/compare/v6.0.12...v6.1.0
[6.0.12]: https://github.com/privacybydesign/irmamobile/compare/v6.0.11...v6.0.12
[6.0.11]: https://github.com/privacybydesign/irmamobile/compare/v6.0.10...v6.0.11
[6.0.10]: https://github.com/privacybydesign/irmamobile/compare/6be351c9...v6.0.10
[6.0.9]: https://github.com/privacybydesign/irmamobile/compare/7f53f7cb...6be351c9
[6.0.8]: https://github.com/privacybydesign/irmamobile/compare/b94760ce...7f53f7cb
[6.0.5]: https://github.com/privacybydesign/irmamobile/compare/fe61622a...b94760ce
[6.0.4]: https://github.com/privacybydesign/irmamobile/compare/2b66156e...fe61622a
[6.0.3]: https://github.com/privacybydesign/irmamobile/compare/b03eed86...2b66156e
[6.0.2]: https://github.com/privacybydesign/irmamobile/compare/ad77578c...b03eed86
[6.0.1]: https://github.com/privacybydesign/irmamobile/compare/5c6dc0c4...ad77578c
[6.0.0]: https://github.com/privacybydesign/irmamobile/tree/5c6dc0c4c
