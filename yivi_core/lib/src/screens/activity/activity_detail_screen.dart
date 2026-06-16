import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:intl/intl.dart";

import "../../models/log_entry.dart";
import "../../theme/theme.dart";
import "../../widgets/irma_app_bar.dart";
import "widgets/activity_detail_disclosure.dart";
import "widgets/activity_detail_issuance.dart";
import "widgets/activity_detail_removal.dart";

class ActivityDetailsScreenArgs {
  final LogInfo logEntry;

  ActivityDetailsScreenArgs({required this.logEntry});
}

class ActivityDetailsScreen extends StatelessWidget {
  final LogInfo logEntry;

  ActivityDetailsScreen({required ActivityDetailsScreenArgs args})
    : logEntry = args.logEntry;

  @override
  Widget build(BuildContext context) {
    final lang = FlutterI18n.currentLocale(context)!.languageCode;
    final localTime = logEntry.time.toLocal();
    final dateAtTime = FlutterI18n.translate(
      context,
      "credential.date_at_time",
      translationParams: {
        "date": DateFormat.yMMMMd(lang).format(localTime),
        "time": DateFormat.jm(lang).format(localTime),
      },
    );

    return Scaffold(
      backgroundColor: context.colors.surfaceContainerHigh,
      appBar: IrmaAppBar(
        title: Text(dateAtTime, style: context.yivi.activity.detailDate),
      ),
      body: SizedBox(
        height: double.infinity,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(context.yivi.defaultSpacing),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(
                  builder: (context) {
                    return switch (logEntry.type) {
                      LogType.disclosure || LogType.signature =>
                        ActivityDetailDisclosure(logEntry: logEntry),
                      LogType.issuance => ActivityDetailIssuance(
                        logEntry: logEntry,
                      ),
                      LogType.removal => ActivityDetailRemoval(
                        logEntry: logEntry,
                      ),
                    };
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
