import "package:flutter/widgets.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../models/schemaless/schemaless_events.dart";

/// Builds extra content rendered at the bottom of a credential card for a given
/// stored credential — e.g. the F-Droid build's face-verification assurance
/// level. Returns `null` for credentials that should not show anything.
typedef FaceCredentialContentBuilder =
    Widget? Function(BuildContext context, Credential credential);

/// Defaults to `null` (no extra content). The F-Droid build overrides this via
/// [runYiviApp]'s `faceCredentialContent` argument, so the assurance attribute
/// only appears there and every other app leaves the card unchanged.
final faceCredentialContentProvider = Provider<FaceCredentialContentBuilder?>(
  (ref) => null,
);
