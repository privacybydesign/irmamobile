import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";

import "package:yivi_core/src/data/irma_bridge.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/schemaless/session_state.dart";
import "package:yivi_core/src/models/translated_value.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/screens/activity/widgets/recent_activity.dart";
import "package:yivi_core/src/theme/theme.dart";

/// Records every event the repository forwards to the (native) bridge, so the
/// test can observe the [LoadLogsEvent]s that [RecentActivity] dispatches.
class _RecordingBridge extends IrmaBridge {
  final dispatched = <Event>[];

  @override
  void dispatch(Event event) => dispatched.add(event);
}

SessionState _sessionState(SessionStatus status) => SessionState(
  id: 1,
  protocol: "irma",
  type: SessionType.disclosure,
  status: status,
  requestor: TrustedParty(
    id: "requestor",
    name: TranslatedValue.fromString("Requestor"),
    url: null,
    parent: null,
    verified: true,
  ),
);

Widget _testWidget(IrmaRepository repo) => IrmaRepositoryProvider(
  repository: repo,
  child: IrmaTheme(
    builder: (_) => MaterialApp(
      localizationsDelegates: [
        FlutterI18nDelegate(
          translationLoader: FileTranslationLoader(
            basePath: "assets/locales",
            forcedLocale: const Locale("en", "US"),
          ),
        ),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: RecentActivity(onTap: () {})),
    ),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<IrmaRepository> buildRepo(_RecordingBridge bridge) async {
    SharedPreferences.setMockInitialValues({});
    return IrmaRepository(
      client: bridge,
      preferences: await IrmaPreferences.fromInstance(
        mostRecentTermsUrlNl: "",
        mostRecentTermsUrlEn: "",
      ),
    );
  }

  testWidgets("reloads the logs when a session finishes successfully", (
    tester,
  ) async {
    final bridge = _RecordingBridge();
    final repo = await buildRepo(bridge);
    addTearDown(repo.close);

    await tester.pumpWidget(_testWidget(repo));
    await tester.pump();

    // The widget loads the logs once on first build.
    expect(bridge.dispatched.whereType<LoadLogsEvent>(), hasLength(1));

    repo.dispatch(
      SessionStateEvent(sessionState: _sessionState(SessionStatus.success)),
    );
    await tester.pump();

    // A successful session must trigger a refresh of the recent-activity list.
    expect(
      bridge.dispatched.whereType<LoadLogsEvent>(),
      hasLength(2),
      reason: "a successful session should reload the recent-activity logs",
    );
  });

  testWidgets("does not reload for non-success session states", (tester) async {
    final bridge = _RecordingBridge();
    final repo = await buildRepo(bridge);
    addTearDown(repo.close);

    await tester.pumpWidget(_testWidget(repo));
    await tester.pump();

    expect(bridge.dispatched.whereType<LoadLogsEvent>(), hasLength(1));

    for (final status in [
      SessionStatus.error,
      SessionStatus.dismissed,
      SessionStatus.requestPermission,
    ]) {
      repo.dispatch(SessionStateEvent(sessionState: _sessionState(status)));
      await tester.pump();
    }

    // None of these are a completed session, so the list must not reload.
    expect(bridge.dispatched.whereType<LoadLogsEvent>(), hasLength(1));
  });

  testWidgets("stops reloading once disposed", (tester) async {
    final bridge = _RecordingBridge();
    final repo = await buildRepo(bridge);
    addTearDown(repo.close);

    await tester.pumpWidget(_testWidget(repo));
    await tester.pump();
    expect(bridge.dispatched.whereType<LoadLogsEvent>(), hasLength(1));

    // Dispose the widget by replacing it.
    await tester.pumpWidget(const SizedBox());
    await tester.pump();

    repo.dispatch(
      SessionStateEvent(sessionState: _sessionState(SessionStatus.success)),
    );
    await tester.pump();

    // The cancelled subscription must not dispatch after disposal.
    expect(bridge.dispatched.whereType<LoadLogsEvent>(), hasLength(1));
  });
}
