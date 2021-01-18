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
  IssueWizardEvent({this.wizard, this.wizardContents});

  final IssueWizard wizard;
  final List<IssueWizardItem> wizardContents;
}

@JsonSerializable()
class IssueWizard {
  IssueWizard({
    this.id,
    this.title,
    this.logo,
    this.logoPath,
    this.issues,
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

  factory IssueWizardItem.fromJson(Map<String, dynamic> json) => _$IssueWizardItemFromJson(json);
  Map<String, dynamic> toJson() => _$IssueWizardItemToJson(this);
}
