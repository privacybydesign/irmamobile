import "package:flutter_riverpod/flutter_riverpod.dart";

import "../models/log_entry.dart";
import "irma_repository_provider.dart";

/// The disclosures (and signatures) of the card with [hash], newest first:
/// who it was shared with, and when. The last 50 are enough to know.
final cardSharesProvider = FutureProvider.autoDispose
    .family<List<LogInfo>, String>((ref, hash) async {
      final page = await ref
          .read(activityLogClientProvider)
          .queryLogs(
            LogQuery(
              filter: LogFilter(
                types: const [LogType.disclosure, LogType.signature],
                credentialHash: hash,
              ),
              limit: 50,
            ),
          );
      return page.entries;
    });
