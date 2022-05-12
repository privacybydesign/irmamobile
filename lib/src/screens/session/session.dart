class SessionScreenArguments {
  final int sessionID;
  final String sessionType;
  final bool hasUnderlyingSession;
  final bool wizardActive;
  final String? wizardCred;

  SessionScreenArguments({
    required this.sessionID,
    required this.sessionType,
    required this.hasUnderlyingSession,
    required this.wizardActive,
    this.wizardCred,
  });
}
