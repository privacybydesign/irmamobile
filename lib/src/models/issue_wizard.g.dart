// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'issue_wizard.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetIssueWizardContentsEvent _$GetIssueWizardContentsEventFromJson(Map<String, dynamic> json) {
  return GetIssueWizardContentsEvent(
    id: json['ID'] as String,
  );
}

Map<String, dynamic> _$GetIssueWizardContentsEventToJson(GetIssueWizardContentsEvent instance) => <String, dynamic>{
      'ID': instance.id,
    };

IssueWizardContentsEvent _$IssueWizardContentsEventFromJson(Map<String, dynamic> json) {
  return IssueWizardContentsEvent(
    id: json['ID'] as String,
    wizardContents: (json['WizardContents'] as List<dynamic>)
        .map((e) => IssueWizardItem.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

Map<String, dynamic> _$IssueWizardContentsEventToJson(IssueWizardContentsEvent instance) => <String, dynamic>{
      'ID': instance.id,
      'WizardContents': instance.wizardContents,
    };

IssueWizard _$IssueWizardFromJson(Map<String, dynamic> json) {
  return IssueWizard(
    id: json['id'] as String,
    title: TranslatedValue.fromJson(json['title'] as Map<String, dynamic>?),
    allowOtherRequestors: json['allowOtherRequestors'] as bool,
    logo: json['logo'] as String?,
    logoPath: json['logoPath'] as String?,
    color: json['color'] as String?,
    textColor: json['textColor'] as String?,
    issues: json['issues'] as String?,
    info: TranslatedValue.fromJson(json['info'] as Map<String, dynamic>?),
    faq: (json['faq'] as List<dynamic>?)?.map((e) => IssueWizardQA.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    intro: TranslatedValue.fromJson(json['intro'] as Map<String, dynamic>?),
    successHeader: TranslatedValue.fromJson(json['successHeader'] as Map<String, dynamic>?),
    successText: TranslatedValue.fromJson(json['successText'] as Map<String, dynamic>?),
    expandDependencies: json['expandDependencies'] as bool? ?? false,
  );
}

Map<String, dynamic> _$IssueWizardToJson(IssueWizard instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'logo': instance.logo,
      'logoPath': instance.logoPath,
      'color': instance.color,
      'textColor': instance.textColor,
      'issues': instance.issues,
      'allowOtherRequestors': instance.allowOtherRequestors,
      'info': instance.info,
      'faq': instance.faq,
      'intro': instance.intro,
      'successHeader': instance.successHeader,
      'successText': instance.successText,
      'expandDependencies': instance.expandDependencies,
    };

IssueWizardQA _$IssueWizardQAFromJson(Map<String, dynamic> json) {
  return IssueWizardQA(
    question: TranslatedValue.fromJson(json['question'] as Map<String, dynamic>?),
    answer: TranslatedValue.fromJson(json['answer'] as Map<String, dynamic>?),
  );
}

Map<String, dynamic> _$IssueWizardQAToJson(IssueWizardQA instance) => <String, dynamic>{
      'question': instance.question,
      'answer': instance.answer,
    };

IssueWizardItem _$IssueWizardItemFromJson(Map<String, dynamic> json) {
  return IssueWizardItem(
    type: json['type'] as String,
    credential: json['credential'] as String?,
    header: TranslatedValue.fromJson(json['header'] as Map<String, dynamic>?),
    text: TranslatedValue.fromJson(json['text'] as Map<String, dynamic>?),
    label: TranslatedValue.fromJson(json['label'] as Map<String, dynamic>?),
    sessionURL: json['sessionUrl'] as String?,
    url: TranslatedValue.fromJson(json['url'] as Map<String, dynamic>?),
    inApp: json['inapp'] as bool? ?? false,
    completed: json['completed'] as bool? ?? false,
  );
}

Map<String, dynamic> _$IssueWizardItemToJson(IssueWizardItem instance) => <String, dynamic>{
      'type': instance.type,
      'credential': instance.credential,
      'header': instance.header,
      'text': instance.text,
      'label': instance.label,
      'sessionUrl': instance.sessionURL,
      'url': instance.url,
      'inapp': instance.inApp,
      'completed': instance.completed,
    };
