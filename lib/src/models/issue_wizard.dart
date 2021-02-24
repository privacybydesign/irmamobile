import 'package:irmamobile/src/models/event.dart';
import 'package:irmamobile/src/models/translated_value.dart';
import 'package:json_annotation/json_annotation.dart';

part 'issue_wizard.g.dart';

@JsonSerializable()
class GetIssueWizardContentsEvent extends Event {
  GetIssueWizardContentsEvent({this.id});

  @JsonKey(name: 'ID')
  final String id;

  factory GetIssueWizardContentsEvent.fromJson(Map<String, dynamic> json) =>
      _$GetIssueWizardContentsEventFromJson(json);
  Map<String, dynamic> toJson() => _$GetIssueWizardContentsEventToJson(this);
}

@JsonSerializable()
class IssueWizardContentsEvent extends Event {
  IssueWizardContentsEvent({this.id, this.wizardContents});

  @JsonKey(name: 'ID')
  final String id;

  @JsonKey(name: 'WizardContents')
  final List<IssueWizardItem> wizardContents;

  factory IssueWizardContentsEvent.fromJson(Map<String, dynamic> json) => _$IssueWizardContentsEventFromJson(json);
  Map<String, dynamic> toJson() => _$IssueWizardContentsEventToJson(this);
}

class IssueWizardEvent extends Event {
  IssueWizardEvent({this.wizardData, this.wizardContents, this.haveCredential = false});

  final IssueWizard wizardData;
  final List<IssueWizardItem> wizardContents;
  final bool haveCredential;

  bool get showSuccess => wizardData.successHeader != null && wizardData.successText != null;
  bool get completed => haveCredential || wizardContents.every((item) => item.completed);
  IssueWizardItem get activeItem => wizardContents.firstWhere((item) => !item.completed, orElse: () => null);
  int get _activeItemIndex => wizardContents.indexWhere((item) => !item.completed);

  /// A copy of the event with the currently active item marked completed.
  IssueWizardEvent get nextEvent => IssueWizardEvent(
        wizardData: wizardData,
        haveCredential: haveCredential,
        wizardContents: wizardContents
            .asMap()
            .entries
            .map((e) => e.value.copyWith(completed: e.key == _activeItemIndex || e.value.completed))
            .toList(),
      );
}

@JsonSerializable()
class IssueWizard {
  IssueWizard({
    this.id,
    this.title,
    this.logo,
    this.logoPath,
    this.issues,
    this.allowOtherRequestors,
    this.info,
    this.faq,
    this.intro,
    this.successHeader,
    this.successText,
    this.expandDependencies,
  });

  @JsonKey(name: 'id')
  final String id;

  @JsonKey(name: 'title')
  final TranslatedValue title;

  @JsonKey(name: 'logo')
  final String logo;

  @JsonKey(name: 'logoPath')
  final String logoPath;

  @JsonKey(name: 'issues')
  final String issues;

  @JsonKey(name: 'allowOtherRequestors')
  final bool allowOtherRequestors;

  @JsonKey(name: 'info')
  final TranslatedValue info;

  @JsonKey(name: 'faq')
  final List<IssueWizardQA> faq;

  @JsonKey(name: 'intro')
  final TranslatedValue intro;

  @JsonKey(name: 'successHeader')
  final TranslatedValue successHeader;

  @JsonKey(name: 'successText')
  final TranslatedValue successText;

  @JsonKey(name: 'expandDependencies')
  final bool expandDependencies;

  factory IssueWizard.fromJson(Map<String, dynamic> json) => _$IssueWizardFromJson(json);
  Map<String, dynamic> toJson() => _$IssueWizardToJson(this);
}

@JsonSerializable()
class IssueWizardQA {
  IssueWizardQA({this.question, this.answer});

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
    this.type,
    this.credential,
    this.header,
    this.text,
    this.label,
    this.sessionURL,
    this.url,
    this.inApp,
    this.completed,
  });

  @JsonKey(name: 'type')
  final String type;

  @JsonKey(name: 'credential')
  final String credential;

  @JsonKey(name: 'header')
  final TranslatedValue header;

  @JsonKey(name: 'text')
  final TranslatedValue text;

  @JsonKey(name: 'label')
  final TranslatedValue label;

  @JsonKey(name: 'sessionUrl')
  final String sessionURL;

  @JsonKey(name: 'url')
  final TranslatedValue url;

  @JsonKey(name: 'inapp')
  final bool inApp;

  final bool completed;

  IssueWizardItem copyWith({
    String type,
    String credential,
    TranslatedValue header,
    TranslatedValue text,
    TranslatedValue label,
    String sessionURL,
    TranslatedValue url,
    bool inApp,
    bool completed,
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
