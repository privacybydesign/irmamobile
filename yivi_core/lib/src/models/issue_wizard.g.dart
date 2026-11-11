// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'issue_wizard.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IssueWizard _$IssueWizardFromJson(Map<String, dynamic> json) => IssueWizard(
  id: json['id'] as String,
  title: TranslatedValue.fromJson(json['title'] as Map<String, dynamic>?),
  allowOtherRequestors: json['allowOtherRequestors'] as bool,
  logo: json['logo'] as String?,
  logoPath: json['logoPath'] as String?,
  color: json['color'] as String?,
  textColor: json['textColor'] as String?,
  issues: json['issues'] as String?,
  info: json['info'] == null
      ? const TranslatedValue.empty()
      : TranslatedValue.fromJson(json['info'] as Map<String, dynamic>?),
  faq:
      (json['faq'] as List<dynamic>?)
          ?.map((e) => IssueWizardQA.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  intro: json['intro'] == null
      ? const TranslatedValue.empty()
      : TranslatedValue.fromJson(json['intro'] as Map<String, dynamic>?),
  successHeader: json['successHeader'] == null
      ? const TranslatedValue.empty()
      : TranslatedValue.fromJson(
          json['successHeader'] as Map<String, dynamic>?,
        ),
  successText: json['successText'] == null
      ? const TranslatedValue.empty()
      : TranslatedValue.fromJson(json['successText'] as Map<String, dynamic>?),
  expandDependencies: json['expandDependencies'] as bool? ?? false,
);

Map<String, dynamic> _$IssueWizardToJson(IssueWizard instance) =>
    <String, dynamic>{
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

IssueWizardQA _$IssueWizardQAFromJson(Map<String, dynamic> json) =>
    IssueWizardQA(
      question: TranslatedValue.fromJson(
        json['question'] as Map<String, dynamic>?,
      ),
      answer: TranslatedValue.fromJson(json['answer'] as Map<String, dynamic>?),
    );

Map<String, dynamic> _$IssueWizardQAToJson(IssueWizardQA instance) =>
    <String, dynamic>{'question': instance.question, 'answer': instance.answer};
