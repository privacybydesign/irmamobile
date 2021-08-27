# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [6.2.1] - in beta 2021-08-27
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


[6.2.0]: https://github.com/privacybydesign/irmamobile/compare/v6.2.0...v6.2.1
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
