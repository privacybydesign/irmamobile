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

class YiviCredentialStyles {
  final TextStyle name;
  final TextStyle attributeEyebrow;
  final TextStyle attributeBulletValue;
  final TextStyle Function(Color color) attributeValue;
  final TextStyle Function(Color color) expiryNote;
  final TextStyle Function(Color color) statusText;

  const YiviCredentialStyles({
    required this.name,
    required this.attributeEyebrow,
    required this.attributeBulletValue,
    required this.attributeValue,
    required this.expiryNote,
    required this.statusText,
  });
}

class YiviActivityStyles {
  final TextStyle cardTitle;
  final TextStyle detailDate;

  const YiviActivityStyles({required this.cardTitle, required this.detailDate});
}

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
  final TextStyle Function(Color color) actionBody;

  const YiviCardStyles({
    required this.notificationBody,
    required this.quoteBody,
    required this.tileLabel,
    required this.actionBody,
  });
}

class YiviButtonStyles {
  final TextStyle searchCancel;
  final TextStyle Function(Color color) label;
  final TextStyle Function(Color color) smallLabel;

  const YiviButtonStyles({
    required this.searchCancel,
    required this.label,
    required this.smallLabel,
  });
}

class YiviSectionStyles {
  final TextStyle header;

  const YiviSectionStyles({required this.header});
}

class YiviRequestorStyles {
  final TextStyle name;

  const YiviRequestorStyles({required this.name});
}

class YiviBottomSheetStyles {
  final TextStyle title;

  const YiviBottomSheetStyles({required this.title});
}

class YiviMiscStyles {
  final TextStyle avatarInitials;
  final TextStyle versionLabel;

  const YiviMiscStyles({
    required this.avatarInitials,
    required this.versionLabel,
  });
}
