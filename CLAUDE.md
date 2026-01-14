# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Yivi (formerly IRMA) is a privacy-friendly authentication app built with Flutter and Go. The app manages user cards containing personal data, allowing selective disclosure and digital signatures. During the transition from IRMA to Yivi, both names may appear interchangeably in the codebase.

The project consists of three main Flutter packages:
- **yivi_core**: Core library containing all business logic, UI components, and the Go bridge
- **yivi_app**: App Store/Play Store version with Google ML Kit for OCR (non-FOSS dependencies)
- **yivi_fdroid**: F-Droid version without proprietary dependencies

## Development Commands

The project uses `just` as a task runner. Run `just --list` to see all available commands.

### Common Commands

```bash
# Build and run
just run                    # Run App Store/Play Store version
just run --flavor alpha     # Run Android with alpha flavor (recommended for development)
just run-fdroid             # Run F-Droid version

# Testing
just unit-test             # Run unit tests in yivi_core
just test                  # Interactive test selector (uses fzf)
just test-all              # Run all integration tests
just test-all --flavor alpha  # Run integration tests on Android

# Code generation and building
just gen                   # Generate JSON serialization code
just bind                  # Generate Go bindings (irmagobridge)
just build                 # Build app (pass flutter build args)

# Code quality
just fmt                   # Format Dart and Go code
just check-fmt             # Check formatting
just lint                  # Run static analysis and linting
```

### Platform-Specific Notes

**Android**: Always specify a flavor when running:
- `--flavor alpha`: For development (doesn't open universal links)
- `--flavor beta`: For testing universal links (requires uninstalling Play Store version)

**iOS**: No custom flavor needed. Run `flutter run` directly or use `just run`.

## Architecture

### Multi-Package Structure

The codebase uses a Flutter plugin architecture:

- **yivi_core** (lib/yivi_core): Flutter plugin containing all core functionality
  - Entry point: `runYiviApp()` function in `yivi_core.dart`
  - Acts as both a Flutter app and a plugin package
  - Contains Go bridge (`irmagobridge/`) for native IRMA client integration

- **yivi_app** (lib/yivi_app): Thin wrapper that adds Google ML Kit OCR processor
  - Entry point: `main.dart` calls `runYiviApp()` with `GoogleMLKitOcrProcessor`

- **yivi_fdroid** (lib/yivi_fdroid): FOSS-only version without OCR processor
  - Entry point: `main.dart` calls `runYiviApp()` without OCR processor

### State Management

The app uses a hybrid approach:
- **Riverpod**: For dependency injection and app-wide state (providers in `src/providers/`)
- **BLoC**: For feature-specific state management (e.g., `NotificationsBloc`)
- **RxDart**: For reactive streams throughout the codebase

Key providers:
- `irmaRepositoryProvider`: Main repository for IRMA operations
- `preferencesProvider`: User preferences and settings
- `ocrProcessorProvider`: OCR implementation (optional, injected from app layer)
- `passportIssuerProvider`: Passport issuance functionality

### Navigation

Uses `go_router` for declarative routing. All routes defined in `routing.dart:60+`.

Key navigation patterns:
- Route guards check enrollment status and redirect unenrolled users
- Global navigator key: `rootNavigatorKey` for app-wide navigation
- Route observer: `routeObserver` for lifecycle tracking
- Whitelisted routes when locked: `/reset_pin`, `/loading`, `/enrollment`, `/scanner`, `/modal_pin`

### Go Bridge Architecture

The Go bridge (`irmagobridge/`) connects Flutter to the IRMA Go client (`irmago`):

- **bridge.go**: Main bridge initialization and lifecycle
- **client_handler.go**: IRMA client operations
- **session_handler.go**: Session management (disclosure, issuance, signing)
- **event_handler.go**: Event dispatching to Flutter
- **events.go**: Event type definitions

Communication flow:
1. Flutter calls Go methods via platform channels (`IrmaBridge` class)
2. Go bridge processes requests using `irmago` library
3. Events stream back to Flutter through `_eventSubject` in `IrmaRepository`
4. `SessionRepository` handles session-specific event processing

### Directory Structure (yivi_core/lib/src/)

- **data/**: Repository layer and data management
  - `irma_repository.dart`: Main repository coordinating all IRMA operations
  - `session_repository.dart`: Manages disclosure/issuance/signing sessions
  - `irma_bridge.dart`: Platform channel interface to Go code
  - `irma_preferences.dart`: Shared preferences wrapper

- **models/**: Data models with JSON serialization (generated code via `json_serializable`)

- **providers/**: Riverpod providers for dependency injection

- **screens/**: Feature-based screen organization
  - Each screen typically has its own directory with widgets and BLoC if needed
  - Major flows: enrollment, session, issue_wizard, documents (passport/ID reading)

- **widgets/**: Shared UI components

- **theme/**: Theme and styling definitions

- **util/**: Utility functions and helpers

## Code Generation

After modifying models with `@JsonSerializable()`:
```bash
just gen
# Or manually:
cd yivi_core && dart run build_runner build --delete-conflicting-outputs
```

After modifying Go code in `irmagobridge/` or updating `irmago`:
```bash
just bind
# Or manually:
./bind_go.sh
```

The `bind_go.sh` script:
- Uses `gomobile bind` to generate Android (AAR) and iOS (xcframework) bindings
- Targets Android API 26+ and iOS 15.6+
- Creates symlink for `irma_configuration` assets

## Submodules

The repository uses Git submodules:
- `irma_configuration`: IRMA scheme configuration files

Initialize with: `git submodule init && git submodule update`

## Testing

### Integration Tests

Located in `yivi_app/integration_test/`. Tests cover issuance, disclosure, and signing flows.

Run on simulator/emulator:
```bash
cd yivi_app
flutter test integration_test/test_all.dart --flavor=alpha  # Android
flutter test integration_test/test_all.dart                # iOS
```

Native Android test:
```bash
cd yivi_app/android && ./gradlew app:connectedAlphaDebugAndroidTest -Ptarget=`pwd`/../integration_test/test_all.dart
```

Native iOS test:
```bash
flutter build ios integration_test/issuance_test.dart --config-only
# Then open ios/Runner.xcworkspace in Xcode and run tests via Product > Test
```

## Linting and Formatting

The project enforces specific code style:
- **Double quotes** preferred over single quotes (`prefer_double_quotes`)
- **Relative imports** required (`prefer_relative_imports`)
- **Directive ordering** enforced (`directives_ordering`)
- Based on `flutter_lints` package

Run checks before committing:
```bash
just lint  # Runs check-fmt and flutter analyze on all packages
```

## Build Flavors and Variants

### Android Flavors
- **alpha**: Development flavor, no universal links, uses alpha app ID
- **beta**: Testing flavor with universal links, uses beta app ID
- **production**: Not defined in code; production builds use default configuration

### iOS Configurations
Standard Debug/Release configurations. No custom flavors.

## Troubleshooting

**Go bridge compilation fails**:
- Rerun `./bind_go.sh` after any Go code changes
- Check NDK version (set `ANDROID_NDK_HOME` if needed)
- Ensure Go 1.17+ and compatible NDK version

**Flavor errors on Android**:
- Always specify `--flavor alpha` or `--flavor beta` when running/building for Android

**Flutter cache issues (iOS)**:
```bash
pushd $(which flutter)/../
rm -rf ./cache
flutter doctor
flutter precache --ios
popd
flutter pub get
cd ./ios && pod install
```

**Windows development**:
Create manual symlink: `mklink /d .\android\app\src\main\assets\irma_configuration .\irma_configuration`

## Editing irmago Directly

For debugging Go code in `irmago`:
```bash
cd yivi_core
go mod edit -replace github.com/privacybydesign/irmago=<local_irmago_path>
go mod tidy
../bind_go.sh
```

**Important**: Never commit changes to `go.mod` or `go.sum` when using local irmago.

## CI/CD

Build automation uses Fastlane (see `fastlane/README.md`). GitHub Actions workflows:
- **Status checks**: Linting, testing, building on PRs
- **Delivery**: Automated builds for master merges and releases

## Prototypes

Run prototype menu: `flutter run -t lib/main_prototypes.dart`

This mode is used for UI/UX experimentation and isolated feature testing.
