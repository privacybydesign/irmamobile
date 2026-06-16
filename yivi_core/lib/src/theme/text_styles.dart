import "package:flutter/material.dart";

import "theme.dart";

// Domain-named text styles grouped by usage area.
//
// Convention: one name per *role*. Variable-color/variable-shape variants are
// builder methods (e.g. `theme.credential.expiryNote(color)`). Do NOT
// `copyWith` on these styles at call sites — if you need a variant, add a new
// named entry or a new builder here.

class YiviCredentialStyles {
  final TextStyle name;
  final TextStyle attributeEyebrow;
  final TextStyle attributeBulletValue;
  final TextStyle Function(Color color) attributeValue;
  final TextStyle Function(Color color) expiryNote;
  // "Revoked" / "Expired" / "About to expire" status text above a credential
  // card header. Color is state-driven (error / warning).
  final TextStyle Function(Color color) statusText;

  YiviCredentialStyles({
    required this.name,
    required this.attributeEyebrow,
    required this.attributeBulletValue,
    required this.attributeValue,
    required this.expiryNote,
    required this.statusText,
  });

  factory YiviCredentialStyles.fromTheme(IrmaThemeData theme) {
    return YiviCredentialStyles(
      // TODO Phase 2: snap to 18 or extend scale to include 19.
      name: TextStyle(
        fontFamily: theme.primaryFontFamily,
        fontSize: 19,
        fontWeight: FontWeight.w600,
        color: theme.dark,
        height: 26 / 19,
      ),
      attributeEyebrow: TextStyle(
        fontFamily: theme.secondaryFontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: theme.neutralDark,
        letterSpacing: 0.96,
      ),
      // Tighter line height for stacked list items (bullets) so successive
      // values don't drift apart vertically.
      attributeBulletValue: TextStyle(
        fontFamily: theme.primaryFontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: theme.dark,
        height: 1.2,
      ),
      attributeValue: (color) => TextStyle(
        fontFamily: theme.primaryFontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      expiryNote: (color) => theme.textTheme.bodyLarge!.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      statusText: (color) =>
          theme.textTheme.headlineMedium!.copyWith(color: color),
    );
  }
}

class YiviActivityStyles {
  final TextStyle cardTitle;
  final TextStyle detailDate;

  YiviActivityStyles({required this.cardTitle, required this.detailDate});

  factory YiviActivityStyles.fromTheme(IrmaThemeData theme) {
    return YiviActivityStyles(
      cardTitle: theme.textTheme.headlineMedium!.copyWith(
        fontSize: 16,
        color: theme.dark,
      ),
      detailDate: theme.textTheme.displaySmall!.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: theme.dark,
      ),
    );
  }
}

class YiviPinStyles {
  final TextStyle keypadDigit;
  final TextStyle keypadSubtitle;
  final TextStyle warningHeading;
  final TextStyle warningButton;
  final TextStyle Function(bool visible) counter;
  final TextStyle Function(double height, bool completed) box;

  YiviPinStyles({
    required this.keypadDigit,
    required this.keypadSubtitle,
    required this.warningHeading,
    required this.warningButton,
    required this.counter,
    required this.box,
  });

  factory YiviPinStyles.fromTheme(IrmaThemeData theme) {
    return YiviPinStyles(
      keypadDigit: TextStyle(
        fontFamily: theme.secondaryFontFamily,
        fontSize: 32,
        height: 32 / 40,
        fontWeight: FontWeight.w600,
        color: theme.secondary,
      ),
      keypadSubtitle: TextStyle(
        fontFamily: theme.secondaryFontFamily,
        height: 14 / 24,
        fontWeight: FontWeight.w400,
        color: theme.secondary,
      ),
      warningHeading: theme.textTheme.headlineSmall!.copyWith(
        fontWeight: FontWeight.w700,
      ),
      warningButton: theme.textTheme.bodySmall!.copyWith(
        fontWeight: FontWeight.w700,
        color: theme.warning,
      ),
      counter: (visible) => theme.textTheme.bodySmall!.copyWith(
        fontWeight: FontWeight.w300,
        color: visible ? theme.secondary : Colors.transparent,
      ),
      // `boxHeight` is the box's outer height in logical pixels — the digit's
      // fontSize scales from it so the glyph sits proportionally inside.
      box: (boxHeight, completed) => theme.textTheme.displaySmall!.copyWith(
        fontSize: boxHeight / 2 + 4,
        height: 22.0 / 18.0,
        color: completed ? theme.secondary : Colors.grey,
      ),
    );
  }
}

class YiviVerificationStyles {
  final TextStyle codeChar;

  YiviVerificationStyles({required this.codeChar});

  factory YiviVerificationStyles.fromTheme(IrmaThemeData theme) {
    return YiviVerificationStyles(
      codeChar: const TextStyle(
        fontSize: 25,
        fontWeight: FontWeight.w600,
        color: Color.fromRGBO(30, 60, 87, 1),
      ),
    );
  }
}

class YiviNfcStyles {
  final TextStyle statusTitle;
  final TextStyle progressTip;

  YiviNfcStyles({required this.statusTitle, required this.progressTip});

  factory YiviNfcStyles.fromTheme(IrmaThemeData theme) {
    return YiviNfcStyles(
      statusTitle: theme.textTheme.bodyLarge!.copyWith(fontSize: 20),
      progressTip: TextStyle(
        fontSize: 16,
        color: theme.secondary,
        height: 1.4,
        overflow: TextOverflow.visible,
      ),
    );
  }
}

class YiviFormStyles {
  final TextStyle errorMessage;
  final TextStyle inputHint;
  final TextStyle explanation;
  // Bold header at the top of an issuance/verification step screen.
  final TextStyle header;

  YiviFormStyles({
    required this.errorMessage,
    required this.inputHint,
    required this.explanation,
    required this.header,
  });

  factory YiviFormStyles.fromTheme(IrmaThemeData theme) {
    return YiviFormStyles(
      errorMessage: TextStyle(color: theme.error),
      inputHint: const TextStyle(color: Colors.grey),
      explanation: theme.textTheme.bodyMedium!.copyWith(
        fontSize: 14,
        color: theme.neutralDark,
      ),
      // Color matches colorScheme.onSurfaceVariant — accessed via the raw
      // field because themeData (and therefore colorScheme) isn't yet
      // initialised when this factory runs.
      header: theme.textTheme.bodyLarge!.copyWith(
        color: theme.neutralExtraDark,
      ),
    );
  }
}

class YiviIndicatorStyles {
  final TextStyle endOfList;
  final TextStyle linearStep;
  final TextStyle Function(bool outlined) circularStep;

  YiviIndicatorStyles({
    required this.endOfList,
    required this.linearStep,
    required this.circularStep,
  });

  factory YiviIndicatorStyles.fromTheme(IrmaThemeData theme) {
    return YiviIndicatorStyles(
      endOfList: theme.textTheme.bodyMedium!.copyWith(
        fontSize: 12,
        height: 18 / 12,
        color: theme.neutralExtraDark,
      ),
      linearStep: TextStyle(fontSize: 12, color: theme.secondary),
      // `outlined` flips the text to the secondary colour so the digit reads
      // against a transparent (outlined) background; otherwise the digit is
      // white over a filled/success background.
      circularStep: (outlined) => theme.textTheme.bodySmall!.copyWith(
        height: 1.2,
        fontWeight: FontWeight.bold,
        color: outlined ? theme.secondary : Colors.white,
      ),
    );
  }
}

class YiviCardStyles {
  final TextStyle notificationBody;
  final TextStyle quoteBody;
  final TextStyle tileLabel;
  final TextStyle Function(Color color) actionBody;

  YiviCardStyles({
    required this.notificationBody,
    required this.quoteBody,
    required this.tileLabel,
    required this.actionBody,
  });

  factory YiviCardStyles.fromTheme(IrmaThemeData theme) {
    return YiviCardStyles(
      notificationBody: theme.textTheme.bodyMedium!.copyWith(
        fontSize: 14,
        color: theme.dark,
      ),
      quoteBody: theme.textTheme.bodyMedium!.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
      tileLabel: theme.textButtonTextStyle.copyWith(
        fontWeight: FontWeight.w400,
        color: theme.dark,
      ),
      actionBody: (color) => theme.textTheme.bodyMedium!.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }
}

class YiviButtonStyles {
  final TextStyle searchCancel;
  final TextStyle Function(Color color) label;
  final TextStyle Function(Color color) smallLabel;

  YiviButtonStyles({
    required this.searchCancel,
    required this.label,
    required this.smallLabel,
  });

  factory YiviButtonStyles.fromTheme(IrmaThemeData theme) {
    return YiviButtonStyles(
      searchCancel: theme.textButtonTextStyle.copyWith(
        fontWeight: FontWeight.normal,
        color: theme.link,
      ),
      label: (color) => theme.textTheme.labelLarge!.copyWith(color: color),
      smallLabel: (color) => theme.textTheme.labelLarge!.copyWith(
        fontFamily: theme.secondaryFontFamily,
        fontSize: 14,
        color: color,
      ),
    );
  }
}

class YiviSectionStyles {
  final TextStyle header;

  YiviSectionStyles({required this.header});

  factory YiviSectionStyles.fromTheme(IrmaThemeData theme) {
    return YiviSectionStyles(
      header: theme.textTheme.headlineMedium!.copyWith(
        color: theme.neutralExtraDark,
      ),
    );
  }
}

class YiviRequestorStyles {
  final TextStyle name;

  YiviRequestorStyles({required this.name});

  factory YiviRequestorStyles.fromTheme(IrmaThemeData theme) {
    return YiviRequestorStyles(
      name: TextStyle(
        fontFamily: theme.primaryFontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: theme.dark,
        height: 26 / 19,
      ),
    );
  }
}

class YiviBottomSheetStyles {
  final TextStyle title;

  YiviBottomSheetStyles({required this.title});

  factory YiviBottomSheetStyles.fromTheme(IrmaThemeData theme) {
    return YiviBottomSheetStyles(
      title: TextStyle(
        fontFamily: theme.primaryFontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: theme.dark,
        height: 26 / 19,
      ),
    );
  }
}

class YiviMiscStyles {
  final TextStyle avatarInitials;
  final TextStyle versionLabel;

  YiviMiscStyles({required this.avatarInitials, required this.versionLabel});

  factory YiviMiscStyles.fromTheme(IrmaThemeData theme) {
    return YiviMiscStyles(
      avatarInitials: TextStyle(
        fontWeight: FontWeight.bold,
        color: theme.neutral,
      ),
      versionLabel: theme.textTheme.titleLarge!.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
