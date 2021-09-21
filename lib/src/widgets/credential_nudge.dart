// This code is not null safe yet.
// @dart=2.11

import 'package:flutter/material.dart';

class CredentialNudge {
  final String fullCredentialTypeId;
  final void Function(BuildContext) showLaunchFailDialog;

  CredentialNudge({
    @required this.fullCredentialTypeId,
    @required this.showLaunchFailDialog,
  });
}

class CredentialNudgeProvider extends InheritedWidget {
  final CredentialNudge credentialNudge;

  const CredentialNudgeProvider({
    Key key,
    @required this.credentialNudge,
    @required Widget child,
  })  : assert(child != null),
        super(
          key: key,
          child: child,
        );

  static CredentialNudgeProvider of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CredentialNudgeProvider>();
  }

  @override
  bool updateShouldNotify(CredentialNudgeProvider oldWidget) => credentialNudge != oldWidget.credentialNudge;
}
