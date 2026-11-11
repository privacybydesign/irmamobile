import "package:json_annotation/json_annotation.dart";

import "translated_value.dart";

part "issue_wizard.g.dart";

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
