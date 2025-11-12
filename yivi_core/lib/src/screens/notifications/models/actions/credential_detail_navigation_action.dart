import 'package:json_annotation/json_annotation.dart';

import 'notification_action.dart';

part 'credential_detail_navigation_action.g.dart';

@JsonSerializable()
class CredentialDetailNavigationAction extends NotificationAction {
  final String credentialTypeId;

  CredentialDetailNavigationAction({
    required this.credentialTypeId,
  });

  factory CredentialDetailNavigationAction.fromJson(Map<String, dynamic> json) =>
      _$CredentialDetailNavigationActionFromJson(json);

  @override
  Map<String, dynamic> toJson() {
    final jsonMap = _$CredentialDetailNavigationActionToJson(this);
    jsonMap['actionType'] = 'credentialDetailNavigationAction';

    return jsonMap;
  }
}
