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

  Map<String, String> toQueryParams() {
    return {
      'session_id': '$sessionID',
      'session_type': sessionType,
      'has_underlying_session': '$hasUnderlyingSession',
      'wizard_active': '$wizardActive',
      if (wizardCred != null) 'wizard_cred': '$wizardCred',
    };
  }

  static SessionScreenArguments fromQueryParams(Map<String, String> params) {
    return SessionScreenArguments(
      sessionID: int.parse(params['session_id']!),
      sessionType: params['session_type']!,
      hasUnderlyingSession: bool.parse(params['has_underlying_session']!),
      wizardActive: bool.parse(params['wizard_active']!),
      wizardCred: params['wizard_cred'],
    );
  }
}
