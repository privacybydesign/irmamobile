// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wizard.dart';

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
    wizardContents: (json['WizardContents'] as List)
        ?.map((e) => e == null ? null : IssueWizardItem.fromJson(e as Map<String, dynamic>))
        ?.toList(),
  );
}

Map<String, dynamic> _$IssueWizardContentsEventToJson(IssueWizardContentsEvent instance) => <String, dynamic>{
      'ID': instance.id,
      'WizardContents': instance.wizardContents,
    };

IssueWizard _$IssueWizardFromJson(Map<String, dynamic> json) {
  return IssueWizard(
    id: json['id'] as String,
    title: json['title'] == null ? null : TranslatedValue.fromJson(json['title'] as Map<String, dynamic>),
    logo: json['logo'] as String,
    issues: json['issues'] as String,
    info: json['info'] == null ? null : TranslatedValue.fromJson(json['info'] as Map<String, dynamic>),
    faq: (json['faq'] as List)
        ?.map((e) => e == null ? null : IssueWizardQA.fromJson(e as Map<String, dynamic>))
        ?.toList(),
    intro: json['intro'] == null ? null : TranslatedValue.fromJson(json['intro'] as Map<String, dynamic>),
    successHeader:
        json['successHeader'] == null ? null : TranslatedValue.fromJson(json['successHeader'] as Map<String, dynamic>),
    successText:
        json['successText'] == null ? null : TranslatedValue.fromJson(json['successText'] as Map<String, dynamic>),
    expandDependencies: json['expandDependencies'] as bool,
  );
}

Map<String, dynamic> _$IssueWizardToJson(IssueWizard instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'logo': instance.logo,
      'issues': instance.issues,
      'info': instance.info,
      'faq': instance.faq,
      'intro': instance.intro,
      'successHeader': instance.successHeader,
      'successText': instance.successText,
      'expandDependencies': instance.expandDependencies,
    };

IssueWizardQA _$IssueWizardQAFromJson(Map<String, dynamic> json) {
  return IssueWizardQA(
    question: json['question'] == null ? null : TranslatedValue.fromJson(json['question'] as Map<String, dynamic>),
    answer: json['answer'] == null ? null : TranslatedValue.fromJson(json['answer'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$IssueWizardQAToJson(IssueWizardQA instance) => <String, dynamic>{
      'question': instance.question,
      'answer': instance.answer,
    };

IssueWizardItem _$IssueWizardItemFromJson(Map<String, dynamic> json) {
  return IssueWizardItem(
    type: json['type'] as String,
    credential: json['credential'] as String,
    header: json['header'] == null ? null : TranslatedValue.fromJson(json['header'] as Map<String, dynamic>),
    text: json['text'] == null ? null : TranslatedValue.fromJson(json['text'] as Map<String, dynamic>),
    label: json['label'] == null ? null : TranslatedValue.fromJson(json['label'] as Map<String, dynamic>),
    sessionURL: json['sessionUrl'] as String,
    url: json['url'] == null ? null : TranslatedValue.fromJson(json['url'] as Map<String, dynamic>),
    inApp: json['inapp'] as bool,
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
    };
