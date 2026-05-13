import "package:collection/collection.dart";
import "package:json_annotation/json_annotation.dart";

import "event.dart";
import "translated_value.dart";

part "issue_wizard.g.dart";

// TODO: remove issue wizard support

class IssueWizardEvent extends Event {
  IssueWizardEvent({
    required this.wizardData,
    required this.wizardContents,
    this.haveCredential = false,
  });

  final IssueWizard wizardData;
  final List<IssueWizardItem> wizardContents;
  final bool haveCredential;

  bool get showSuccess =>
      wizardData.successHeader.isNotEmpty && wizardData.successText.isNotEmpty;
  bool get completed =>
      haveCredential || wizardContents.every((item) => item.completed);
  IssueWizardItem? get activeItem =>
      wizardContents.firstWhereOrNull((item) => !item.completed);
  int get activeItemIndex =>
      wizardContents.indexWhere((item) => !item.completed);

  /// A copy of the event with the currently active item marked completed.
  IssueWizardEvent get nextEvent => IssueWizardEvent(
    wizardData: wizardData,
    haveCredential: haveCredential,
    wizardContents: wizardContents
        .asMap()
        .entries
        .map(
          (e) => e.value.copyWith(
            completed: e.key == activeItemIndex || e.value.completed,
          ),
        )
        .toList(),
  );
}

// Go's IssueWizard has camelCase json tags.
@JsonSerializable(fieldRename: FieldRename.none)
class IssueWizard {
  IssueWizard({
    required this.id,
    required this.title,
    required this.allowOtherRequestors,
    this.logo,
    this.logoPath,
    this.color,
    this.textColor,
    this.issues,
    this.info = const TranslatedValue.empty(),
    this.faq = const [],
    this.intro = const TranslatedValue.empty(),
    this.successHeader = const TranslatedValue.empty(),
    this.successText = const TranslatedValue.empty(),
    this.expandDependencies = false,
  });

  final String id;

  final TranslatedValue title;

  final String? logo;

  final String? logoPath;

  final String? color;

  final String? textColor;

  final String? issues;

  final bool allowOtherRequestors;

  // Default value is set by fromJson of TranslatedValue
  final TranslatedValue info;

  final List<IssueWizardQA> faq;

  // Default value is set by fromJson of TranslatedValue
  final TranslatedValue intro;

  // Default value is set by fromJson of TranslatedValue
  final TranslatedValue successHeader;

  // Default value is set by fromJson of TranslatedValue
  final TranslatedValue successText;

  final bool expandDependencies;

  factory IssueWizard.fromJson(Map<String, dynamic> json) =>
      _$IssueWizardFromJson(json);
  Map<String, dynamic> toJson() => _$IssueWizardToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.none)
class IssueWizardQA {
  IssueWizardQA({required this.question, required this.answer});

  final TranslatedValue question;

  final TranslatedValue answer;

  factory IssueWizardQA.fromJson(Map<String, dynamic> json) =>
      _$IssueWizardQAFromJson(json);
  Map<String, dynamic> toJson() => _$IssueWizardQAToJson(this);
}

// Go's IssueWizardItem has camelCase json tags.
@JsonSerializable(fieldRename: FieldRename.none)
class IssueWizardItem {
  IssueWizardItem({
    required this.type,
    this.credential,
    this.header = const TranslatedValue.empty(),
    this.text = const TranslatedValue.empty(),
    this.label = const TranslatedValue.empty(),
    this.sessionURL,
    this.url = const TranslatedValue.empty(),
    this.inApp = false,
    this.completed = false,
  });

  final String type;

  final String? credential;

  // Default value is set by fromJson of TranslatedValue
  final TranslatedValue header;

  // Default value is set by fromJson of TranslatedValue
  final TranslatedValue text;

  // Default value is set by fromJson of TranslatedValue
  final TranslatedValue label;

  @JsonKey(name: "sessionUrl")
  final String? sessionURL;

  // Default value is set by fromJson of TranslatedValue
  final TranslatedValue url;

  @JsonKey(name: "inapp")
  final bool inApp;

  final bool completed;

  IssueWizardItem copyWith({
    String? type,
    String? credential,
    TranslatedValue? header,
    TranslatedValue? text,
    TranslatedValue? label,
    String? sessionURL,
    TranslatedValue? url,
    bool? inApp,
    bool? completed,
  }) {
    return IssueWizardItem(
      type: type ?? this.type,
      credential: credential ?? this.credential,
      header: header ?? this.header,
      text: text ?? this.text,
      label: label ?? this.label,
      sessionURL: sessionURL ?? this.sessionURL,
      url: url ?? this.url,
      inApp: inApp ?? this.inApp,
      completed: completed ?? this.completed,
    );
  }

  factory IssueWizardItem.fromJson(Map<String, dynamic> json) =>
      _$IssueWizardItemFromJson(json);
  Map<String, dynamic> toJson() => _$IssueWizardItemToJson(this);
}
