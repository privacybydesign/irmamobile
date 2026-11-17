import "package:flutter_riverpod/flutter_riverpod.dart";

import "../models/enrollment_status.dart";
import "../models/error_event.dart";
import "irma_repository_provider.dart";
import "stream_mirror.dart";

/// Whether developer mode is on; off until the Go core says otherwise.
final developerModeProvider = mirrorProvider<bool>(
  (repo) => repo.getDeveloperMode(),
  first: (_) => false,
);

/// Whether this install is enrolled at the keyshare server.
final enrollmentStatusProvider = StreamProvider<EnrollmentStatus>(
  (ref) => ref.watch(irmaRepositoryProvider).getEnrollmentStatus(),
);

/// Errors that stop the app from starting.
final fatalErrorProvider = StreamProvider<ErrorEvent>(
  (ref) => ref.watch(irmaRepositoryProvider).getFatalErrors(),
);
