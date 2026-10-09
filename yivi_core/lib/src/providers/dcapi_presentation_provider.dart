import "package:flutter_riverpod/flutter_riverpod.dart";

/// Whether this engine exists to answer one Digital Credentials API request
/// rather than to be the user's wallet.
///
/// It changes where a finished session leaves the user. The wallet's own
/// Activity has a home screen to return to; this one has a caller waiting on a
/// result and no home at all, so "done" means handing that result back and
/// closing rather than navigating anywhere.
///
/// Overridden once, in `runYiviApp`, from the entry point the Activity started.
/// False everywhere else, which is every other way the app runs.
final dcApiPresentationProvider = Provider<bool>((ref) => false);
