import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';

import 'event.dart';
import 'translated_value.dart';

part 'issue_wizard.g.dart';

@JsonSerializable()
class GetIssueWizardContentsEvent extends Event {
  GetIssueWizardContentsEvent({required this.id});

  @JsonKey(name: 'ID')
  final String id;

  factory GetIssueWizardContentsEvent.fromJson(Map<String, dynamic> json) =>
      _$GetIssueWizardContentsEventFromJson(json);
  Map<String, dynamic> toJson() => _$GetIssueWizardContentsEventToJson(this);
}

@JsonSerializable()
class IssueWizardContentsEvent extends Event {
  IssueWizardContentsEvent({required this.id, required this.wizardContents});

  @JsonKey(name: 'ID')
  final String id;

  @JsonKey(name: 'WizardContents')
  final List<IssueWizardItem> wizardContents;

  factory IssueWizardContentsEvent.fromJson(Map<String, dynamic> json) => _$IssueWizardContentsEventFromJson(json);
  Map<String, dynamic> toJson() => _$IssueWizardContentsEventToJson(this);
}

class IssueWizardEvent extends Event {
  IssueWizardEvent({required this.wizardData, required this.wizardContents, this.haveCredential = false});

  final IssueWizard wizardData;
  final List<IssueWizardItem> wizardContents;
  final bool haveCredential;

  bool get showSuccess => wizardData.successHeader.isNotEmpty && wizardData.successText.isNotEmpty;
  bool get completed => haveCredential || wizardContents.every((item) => item.completed);
  IssueWizardItem? get activeItem => wizardContents.firstWhereOrNull((item) => !item.completed);
  int get activeItemIndex => wizardContents.indexWhere((item) => !item.completed);

  /// A copy of the event with the currently active item marked completed.
  IssueWizardEvent get nextEvent => IssueWizardEvent(
    wizardData: wizardData,
    haveCredential: haveCredential,
    wizardContents: wizardContents
        .asMap()
        .entries
        .map((e) => e.value.copyWith(completed: e.key == activeItemIndex || e.value.completed))
        .toList(),
  );
}

@JsonSerializable()
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

  @JsonKey(name: 'id')
  final String id;

  @JsonKey(name: 'title')
  final TranslatedValue title;

  @JsonKey(name: 'logo')
  final String? logo;

  @JsonKey(name: 'logoPath')
  final String? logoPath;

  @JsonKey(name: 'color')
  final String? color;

  @JsonKey(name: 'textColor')
  final String? textColor;

  @JsonKey(name: 'issues')
  final String? issues;

  @JsonKey(name: 'allowOtherRequestors')
  final bool allowOtherRequestors;

  @JsonKey(name: 'info') // Default value is set by fromJson of TranslatedValue
  final TranslatedValue info;

  @JsonKey(name: 'faq')
  final List<IssueWizardQA> faq;

  @JsonKey(name: 'intro') // Default value is set by fromJson of TranslatedValue
  final TranslatedValue intro;

  @JsonKey(name: 'successHeader') // Default value is set by fromJson of TranslatedValue
  final TranslatedValue successHeader;

  @JsonKey(name: 'successText') // Default value is set by fromJson of TranslatedValue
  final TranslatedValue successText;

  @JsonKey(name: 'expandDependencies')
  final bool expandDependencies;

  factory IssueWizard.fromJson(Map<String, dynamic> json) => _$IssueWizardFromJson(json);
  Map<String, dynamic> toJson() => _$IssueWizardToJson(this);
}

@JsonSerializable()
class IssueWizardQA {
  IssueWizardQA({required this.question, required this.answer});

  @JsonKey(name: 'question')
  final TranslatedValue question;

  @JsonKey(name: 'answer')
  final TranslatedValue answer;

  factory IssueWizardQA.fromJson(Map<String, dynamic> json) => _$IssueWizardQAFromJson(json);
  Map<String, dynamic> toJson() => _$IssueWizardQAToJson(this);
}

@JsonSerializable()
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

  @JsonKey(name: 'type')
  final String type;

  @JsonKey(name: 'credential')
  final String? credential;

  @JsonKey(name: 'header') // Default value is set by fromJson of TranslatedValue
  final TranslatedValue header;

  @JsonKey(name: 'text') // Default value is set by fromJson of TranslatedValue
  final TranslatedValue text;

  @JsonKey(name: 'label') // Default value is set by fromJson of TranslatedValue
  final TranslatedValue label;

  @JsonKey(name: 'sessionUrl')
  final String? sessionURL;

  @JsonKey(name: 'url') // Default value is set by fromJson of TranslatedValue
  final TranslatedValue url;

  @JsonKey(name: 'inapp')
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

  factory IssueWizardItem.fromJson(Map<String, dynamic> json) => _$IssueWizardItemFromJson(json);
  Map<String, dynamic> toJson() => _$IssueWizardItemToJson(this);
}
