// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'issue_wizard.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetIssueWizardContentsEvent _$GetIssueWizardContentsEventFromJson(
  Map<String, dynamic> json,
) => GetIssueWizardContentsEvent(id: json['id'] as String);

Map<String, dynamic> _$GetIssueWizardContentsEventToJson(
  GetIssueWizardContentsEvent instance,
) => <String, dynamic>{'id': instance.id};

IssueWizardContentsEvent _$IssueWizardContentsEventFromJson(
  Map<String, dynamic> json,
) => IssueWizardContentsEvent(
  id: json['id'] as String,
  wizardContents: (json['wizard_contents'] as List<dynamic>)
      .map((e) => IssueWizardItem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$IssueWizardContentsEventToJson(
  IssueWizardContentsEvent instance,
) => <String, dynamic>{
  'id': instance.id,
  'wizard_contents': instance.wizardContents,
};

IssueWizard _$IssueWizardFromJson(Map<String, dynamic> json) => IssueWizard(
  id: json['id'] as String,
  title: TranslatedValue.fromJson(json['title'] as Map<String, dynamic>?),
  allowOtherRequestors: json['allow_other_requestors'] as bool,
  logo: json['logo'] as String?,
  logoPath: json['logo_path'] as String?,
  color: json['color'] as String?,
  textColor: json['text_color'] as String?,
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
  successHeader: json['success_header'] == null
      ? const TranslatedValue.empty()
      : TranslatedValue.fromJson(
          json['success_header'] as Map<String, dynamic>?,
        ),
  successText: json['success_text'] == null
      ? const TranslatedValue.empty()
      : TranslatedValue.fromJson(json['success_text'] as Map<String, dynamic>?),
  expandDependencies: json['expand_dependencies'] as bool? ?? false,
);

Map<String, dynamic> _$IssueWizardToJson(IssueWizard instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'logo': instance.logo,
      'logo_path': instance.logoPath,
      'color': instance.color,
      'text_color': instance.textColor,
      'issues': instance.issues,
      'allow_other_requestors': instance.allowOtherRequestors,
      'info': instance.info,
      'faq': instance.faq,
      'intro': instance.intro,
      'success_header': instance.successHeader,
      'success_text': instance.successText,
      'expand_dependencies': instance.expandDependencies,
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

IssueWizardItem _$IssueWizardItemFromJson(Map<String, dynamic> json) =>
    IssueWizardItem(
      type: json['type'] as String,
      credential: json['credential'] as String?,
      header: json['header'] == null
          ? const TranslatedValue.empty()
          : TranslatedValue.fromJson(json['header'] as Map<String, dynamic>?),
      text: json['text'] == null
          ? const TranslatedValue.empty()
          : TranslatedValue.fromJson(json['text'] as Map<String, dynamic>?),
      label: json['label'] == null
          ? const TranslatedValue.empty()
          : TranslatedValue.fromJson(json['label'] as Map<String, dynamic>?),
      sessionURL: json['session_url'] as String?,
      url: json['url'] == null
          ? const TranslatedValue.empty()
          : TranslatedValue.fromJson(json['url'] as Map<String, dynamic>?),
      inApp: json['in_app'] as bool? ?? false,
      completed: json['completed'] as bool? ?? false,
    );

Map<String, dynamic> _$IssueWizardItemToJson(IssueWizardItem instance) =>
    <String, dynamic>{
      'type': instance.type,
      'credential': instance.credential,
      'header': instance.header,
      'text': instance.text,
      'label': instance.label,
      'session_url': instance.sessionURL,
      'url': instance.url,
      'in_app': instance.inApp,
      'completed': instance.completed,
    };
