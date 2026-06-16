part of "theme.dart";

// Domain-named text styles grouped by usage area.
//
// Convention: one name per *role*. Variable-color/variable-shape variants are
// builder methods (e.g. `theme.credential.expiryNote(color)`). Do NOT
// `copyWith` on these styles at call sites — if you need a variant, add a new
// named entry or a new builder here.
//
// These classes are pure data shapes — the values are constructed in
// `buildYiviThemeData()` in theme.dart.

class YiviPinStyles {
  final TextStyle keypadDigit;
  final TextStyle keypadSubtitle;
  final TextStyle warningHeading;
  final TextStyle warningButton;
  final TextStyle Function(bool visible) counter;
  final TextStyle Function(double height, bool completed) box;

  const YiviPinStyles({
    required this.keypadDigit,
    required this.keypadSubtitle,
    required this.warningHeading,
    required this.warningButton,
    required this.counter,
    required this.box,
  });
}

class YiviVerificationStyles {
  final TextStyle codeChar;

  const YiviVerificationStyles({required this.codeChar});
}

class YiviNfcStyles {
  final TextStyle statusTitle;
  final TextStyle progressTip;

  const YiviNfcStyles({required this.statusTitle, required this.progressTip});
}

class YiviFormStyles {
  final TextStyle errorMessage;
  final TextStyle inputHint;
  final TextStyle explanation;
  final TextStyle header;

  const YiviFormStyles({
    required this.errorMessage,
    required this.inputHint,
    required this.explanation,
    required this.header,
  });
}

class YiviIndicatorStyles {
  final TextStyle endOfList;
  final TextStyle linearStep;
  final TextStyle Function(bool outlined) circularStep;

  const YiviIndicatorStyles({
    required this.endOfList,
    required this.linearStep,
    required this.circularStep,
  });
}

class YiviCardStyles {
  final TextStyle notificationBody;
  final TextStyle quoteBody;
  final TextStyle tileLabel;

  const YiviCardStyles({
    required this.notificationBody,
    required this.quoteBody,
    required this.tileLabel,
  });
}

class YiviMiscStyles {
  final TextStyle avatarInitials;
  final TextStyle versionLabel;

  const YiviMiscStyles({
    required this.avatarInitials,
    required this.versionLabel,
  });
}
